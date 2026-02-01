# Task 002: Core Orchestrator

## Description

Implement the main orchestrator script that manages parallel agent execution. The orchestrator is stateless - it reconstructs its view from Beads on each cycle, making it crash-resilient.

## Dependencies

- 001_initialize_beads - Beads must be set up first

## Success Criteria

1. Script accepts `--epic` and `--max-agents` arguments
2. Spawns worker agents up to max limit for ready tasks
3. All state stored in Beads metadata (worktree, branch, pid, phase, pr_number)
4. Correctly reconstructs state after restart
5. Detects and respawns crashed agents
6. Cleans up worktrees after task completion
7. Exits when all tasks in scope are complete

## Implementation Steps

### 1. Create Script Directory

```bash
mkdir -p scripts
```

### 2. Implement Orchestrator Script

Create `scripts/orchestrate.sh`:

```bash
#!/bin/bash
set -euo pipefail

WORKTREE_BASE="../worktrees"
MAX_AGENTS=4
EPIC_FILTER=""

# ============ ARGUMENT PARSING ============
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -e, --epic EPIC_ID    Only process tasks under this epic
  -m, --max-agents N    Maximum parallel agents (default: 4)
  -h, --help            Show this help

Examples:
  $(basename "$0")                          # All ready tasks
  $(basename "$0") -e lt-a3f8               # Only epic lt-a3f8
  $(basename "$0") --epic lt-a3f8 --max-agents 6
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--epic) EPIC_FILTER="$2"; shift 2 ;;
        -m|--max-agents) MAX_AGENTS="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ============ FILTERED QUERIES ============
get_ready_tasks() {
    local tasks=$(bd ready --json 2>/dev/null | jq -c '.issues // []')
    if [ -n "$EPIC_FILTER" ]; then
        echo "$tasks" | jq -c --arg epic "$EPIC_FILTER" \
            '[.[] | select(.id | startswith($epic + "."))]'
    else
        echo "$tasks"
    fi
}

get_active_tasks() {
    local tasks=$(bd list --json 2>/dev/null | jq -c '[.issues[] | select(.status == "in_progress")]')
    if [ -n "$EPIC_FILTER" ]; then
        echo "$tasks" | jq -c --arg epic "$EPIC_FILTER" \
            '[.[] | select(.id | startswith($epic + "."))]'
    else
        echo "$tasks"
    fi
}

validate_epic() {
    if [ -n "$EPIC_FILTER" ]; then
        if ! bd show "$EPIC_FILTER" &>/dev/null; then
            echo "Error: Epic '$EPIC_FILTER' not found"
            bd list --json | jq -r '.issues[] | select(.id | contains(".") | not) | "  \(.id): \(.subject)"'
            exit 1
        fi
        log "Filtering to epic: $EPIC_FILTER"
    fi
}

# ============ AGENT LIFECYCLE ============
spawn_agent() {
    local task_id=$1
    local subject=$2
    local worktree="${WORKTREE_BASE}/${task_id}"
    local branch="agent/${task_id}"

    log "Spawning: $task_id - $subject"

    # Create worktree (idempotent)
    git worktree add "$worktree" -b "$branch" 2>/dev/null || true

    # Record ALL state in Beads
    bd update "$task_id" \
        --status in_progress \
        --meta worktree="$worktree" \
        --meta branch="$branch" \
        --meta phase=spawned \
        --meta spawned_at="$(date -Iseconds)"

    # Launch agent in background
    (
        cd "$worktree"
        bd update "$task_id" --meta phase=working

        # Agent executes task (see 003_worker_agent for full prompt)
        claude --print "$(cat .claude/agents/worker.md | sed "s/\$TASK_ID/$task_id/g")" \
            > agent.log 2>&1 || true
    ) &

    bd update "$task_id" --meta agent_pid="$!"
}

check_agent() {
    local task_id=$1
    local pid=$2
    local phase=$3
    local worktree=$4

    # Still running?
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        log "$task_id: running (phase: $phase)"
        return 0
    fi

    # Process ended - handle based on phase
    case "$phase" in
        spawned|working)
            if [ -d "$worktree" ]; then
                local commits=$(cd "$worktree" && git log origin/main..HEAD --oneline 2>/dev/null | wc -l || echo 0)
                if [ "$commits" -gt 0 ]; then
                    log "$task_id: has commits - advancing to committed"
                    bd update "$task_id" --meta phase=committed --meta agent_pid=""
                else
                    log "$task_id: crashed with no work - respawning"
                    local subject=$(bd show "$task_id" --json | jq -r '.subject')
                    spawn_agent "$task_id" "$subject"
                fi
            fi
            ;;
        committed)
            log "$task_id: pushing and creating PR"
            (
                cd "$worktree"
                git push -u origin HEAD 2>/dev/null || true
                local subject=$(bd show "$task_id" --json | jq -r '.subject')
                gh pr create --title "feat: $subject" --body "Implements $task_id" 2>/dev/null || true
                local pr_num=$(gh pr view --json number -q .number 2>/dev/null || echo "")
                [ -n "$pr_num" ] && bd update "$task_id" --meta phase=pr_created --meta pr_number="$pr_num"
            )
            ;;
        pr_created)
            local pr_num=$(bd show "$task_id" --json | jq -r '.meta.pr_number // empty')
            if [ -n "$pr_num" ]; then
                local state=$(gh pr view "$pr_num" --json state -q .state 2>/dev/null)
                if [ "$state" = "MERGED" ]; then
                    log "$task_id: merged - closing"
                    bd update "$task_id" --meta phase=merged
                    bd close "$task_id"
                    cleanup_worktree "$task_id" "$worktree"
                fi
            fi
            ;;
    esac
}

try_merge() {
    local task_id=$1
    local pr_num=$2
    local worktree=$3

    local ready=$(gh pr view "$pr_num" --json mergeable,statusCheckRollup \
        --jq 'if .mergeable == "MERGEABLE" and (.statusCheckRollup.state == "SUCCESS" or .statusCheckRollup == null) then "yes" else "no" end' 2>/dev/null || echo "no")

    if [ "$ready" = "yes" ]; then
        log "$task_id: merging PR #$pr_num"
        if gh pr merge "$pr_num" --squash --delete-branch 2>/dev/null; then
            bd update "$task_id" --meta phase=merged
            bd close "$task_id"
            cleanup_worktree "$task_id" "$worktree"
        fi
    fi
}

cleanup_worktree() {
    local task_id=$1
    local worktree=$2

    [ -d "$worktree" ] && git worktree remove "$worktree" --force 2>/dev/null || true
    git branch -d "agent/${task_id}" 2>/dev/null || true
}

# ============ MAIN LOOP ============
main() {
    validate_epic
    log "Starting orchestrator (max $MAX_AGENTS agents)"
    mkdir -p "$WORKTREE_BASE"

    while true; do
        # Check active tasks
        active_tasks=$(get_active_tasks)
        echo "$active_tasks" | jq -c '.[]' | while read -r task; do
            [ -z "$task" ] && continue
            task_id=$(echo "$task" | jq -r '.id')
            pid=$(echo "$task" | jq -r '.meta.agent_pid // empty')
            phase=$(echo "$task" | jq -r '.meta.phase // "unknown"')
            worktree=$(echo "$task" | jq -r '.meta.worktree // empty')
            pr_num=$(echo "$task" | jq -r '.meta.pr_number // empty')

            check_agent "$task_id" "$pid" "$phase" "$worktree"
            [ -n "$pr_num" ] && [ "$phase" = "pr_created" ] && try_merge "$task_id" "$pr_num" "$worktree"
        done

        # Spawn new agents if capacity
        active_count=$(get_active_tasks | jq 'length')
        if [ "$active_count" -lt "$MAX_AGENTS" ]; then
            slots=$((MAX_AGENTS - active_count))
            get_ready_tasks | jq -c '.[]' | head -n "$slots" | while read -r task; do
                [ -z "$task" ] && continue
                task_id=$(echo "$task" | jq -r '.id')
                subject=$(echo "$task" | jq -r '.subject')
                spawn_agent "$task_id" "$subject"
            done
        fi

        # Status report
        ready_count=$(get_ready_tasks | jq 'length')
        active_count=$(get_active_tasks | jq 'length')
        log "Status: $active_count active, $ready_count ready"

        # Done?
        if [ "$active_count" -eq 0 ] && [ "$ready_count" -eq 0 ]; then
            log "All tasks complete!"
            break
        fi

        sleep 30
    done
}

main
```

### 3. Make Script Executable

```bash
chmod +x scripts/orchestrate.sh
```

## Test Cases

### Test 1: Argument Parsing
```bash
#!/bin/bash
# Test help
./scripts/orchestrate.sh --help | grep -q "Usage:" || exit 1

# Test invalid epic
./scripts/orchestrate.sh --epic nonexistent 2>&1 | grep -q "not found" || exit 1

echo "PASS: argument parsing"
```

### Test 2: State Reconstruction
```bash
#!/bin/bash
# Create task with metadata (simulating mid-execution state)
task_id=$(bd create "Test reconstruction" --json | jq -r '.id')
bd update "$task_id" --status in_progress \
    --meta phase=working \
    --meta worktree="../worktrees/$task_id"

# Verify orchestrator can read this state
state=$(bd show "$task_id" --json)
[ "$(echo "$state" | jq -r '.meta.phase')" = "working" ] || exit 1

# Cleanup
bd delete "$task_id" --force
echo "PASS: state reconstruction"
```

## Verification Checklist

- [ ] Script created at `scripts/orchestrate.sh`
- [ ] `--help` shows usage information
- [ ] `--epic` filters to specific epic
- [ ] `--max-agents` limits concurrent agents
- [ ] State stored in Beads metadata
- [ ] Crashed agents detected and respawned
- [ ] Worktrees cleaned up after completion
- [ ] Script exits when all tasks done

## Notes

- The orchestrator uses `kill -0 $pid` to check if agent is still running
- Phase transitions are: spawned → working → committed → pr_created → merged
- Each cycle sleeps 30 seconds to avoid hammering GitHub API
- Consider adding `--dry-run` flag for testing

## Files to Modify

- `scripts/orchestrate.sh` - Create orchestrator script

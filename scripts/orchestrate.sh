#!/bin/bash
# ==============================================================================
# orchestrate.sh - Parallel agent orchestrator using Beads for state management
#
# Usage: ./scripts/orchestrate.sh [OPTIONS]
#
# Options:
#   -e, --epic EPIC_ID    Only process tasks under this epic
#   -m, --max-agents N    Maximum parallel agents (default: 4)
#   -d, --dry-run         Show what would happen without executing
#   -h, --help            Show this help
#
# Description:
#   Manages parallel agent execution across isolated git worktrees.
#   Runtime state is stored in Beads notes field as JSON for crash resilience.
#   Uses labels for phase tracking (phase:spawned, phase:working, etc.)
# ==============================================================================
set -euo pipefail

WORKTREE_BASE="../worktrees"
MAX_AGENTS=4
EPIC_FILTER=""
DRY_RUN=false

# State file for runtime info (worktree paths, PIDs, etc.)
STATE_DIR=".beads/orchestrator"
STATE_FILE="$STATE_DIR/state.json"

# ============ ARGUMENT PARSING ============
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -e, --epic EPIC_ID    Only process tasks under this epic
  -m, --max-agents N    Maximum parallel agents (default: 4)
  -d, --dry-run         Show what would happen without executing
  -h, --help            Show this help

Examples:
  $(basename "$0")                          # All ready tasks
  $(basename "$0") -e ghtml-a3f8            # Only epic ghtml-a3f8
  $(basename "$0") --epic ghtml-a3f8 --max-agents 6
  $(basename "$0") --dry-run                # Preview mode
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--epic) EPIC_FILTER="$2"; shift 2 ;;
        -m|--max-agents) MAX_AGENTS="$2"; shift 2 ;;
        -d|--dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

log() { echo "[$(date '+%H:%M:%S')] $*"; }
dry() { $DRY_RUN && echo "[DRY-RUN] $*" && return 0 || return 1; }

# ============ STATE MANAGEMENT ============
# State is stored in a local JSON file, keyed by task ID
# Format: { "task-id": { "worktree": "...", "branch": "...", "pid": "...", "phase": "..." } }

init_state() {
    mkdir -p "$STATE_DIR"
    [ -f "$STATE_FILE" ] || echo '{}' > "$STATE_FILE"
}

get_task_state() {
    local task_id=$1
    jq -r --arg id "$task_id" '.[$id] // empty' "$STATE_FILE"
}

set_task_state() {
    local task_id=$1
    local key=$2
    local value=$3
    local tmp
    tmp=$(mktemp)
    jq --arg id "$task_id" --arg k "$key" --arg v "$value" \
        '.[$id] = (.[$id] // {}) | .[$id][$k] = $v' "$STATE_FILE" > "$tmp"
    mv "$tmp" "$STATE_FILE"
}

get_task_field() {
    local task_id=$1
    local key=$2
    jq -r --arg id "$task_id" --arg k "$key" '.[$id][$k] // empty' "$STATE_FILE"
}

remove_task_state() {
    local task_id=$1
    local tmp
    tmp=$(mktemp)
    jq --arg id "$task_id" 'del(.[$id])' "$STATE_FILE" > "$tmp"
    mv "$tmp" "$STATE_FILE"
}

# ============ FILTERED QUERIES ============
get_ready_tasks() {
    if [ -n "$EPIC_FILTER" ]; then
        bd ready --parent "$EPIC_FILTER" --json 2>/dev/null || echo "[]"
    else
        bd ready --json 2>/dev/null || echo "[]"
    fi
}

get_active_tasks() {
    if [ -n "$EPIC_FILTER" ]; then
        bd list --status in_progress --parent "$EPIC_FILTER" --json 2>/dev/null || echo "[]"
    else
        bd list --status in_progress --json 2>/dev/null || echo "[]"
    fi
}

validate_epic() {
    if [ -n "$EPIC_FILTER" ]; then
        if ! bd show "$EPIC_FILTER" &>/dev/null; then
            echo "Error: Epic '$EPIC_FILTER' not found"
            echo "Available epics:"
            bd list --json | jq -r '.[] | select(.labels[]? == "epic") | "  \(.id): \(.title // .subject)"' 2>/dev/null || echo "  (none)"
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

    if dry "Would spawn agent for $task_id in $worktree"; then
        return 0
    fi

    # Create worktree (idempotent)
    if [ ! -d "$worktree" ]; then
        git worktree add "$worktree" -b "$branch" 2>/dev/null || \
        git worktree add "$worktree" "$branch" 2>/dev/null || true
    fi

    # Update beads status and add phase label
    bd update "$task_id" --status in_progress --add-label "phase:spawned" 2>/dev/null || true

    # Store runtime state locally
    set_task_state "$task_id" "worktree" "$worktree"
    set_task_state "$task_id" "branch" "$branch"
    set_task_state "$task_id" "phase" "spawned"
    set_task_state "$task_id" "spawned_at" "$(date -Iseconds)"

    # Launch agent in background
    (
        cd "$worktree"

        # Update phase
        bd update "$task_id" --remove-label "phase:spawned" --add-label "phase:working" 2>/dev/null || true

        # Agent executes task
        if [ -f ".claude/agents/worker.md" ]; then
            local prompt
            prompt=$(cat .claude/agents/worker.md | sed "s/\$TASK_ID/$task_id/g")
            claude --print "$prompt" > agent.log 2>&1 || true
        else
            # Fallback: simple prompt
            claude --print "Execute beads task $task_id. Run 'bd show $task_id' to see details. Run 'just check' before committing." \
                > agent.log 2>&1 || true
        fi
    ) &

    local pid=$!
    set_task_state "$task_id" "pid" "$pid"
    set_task_state "$task_id" "phase" "working"
}

check_agent() {
    local task_id=$1

    local pid worktree phase
    pid=$(get_task_field "$task_id" "pid")
    worktree=$(get_task_field "$task_id" "worktree")
    phase=$(get_task_field "$task_id" "phase")

    # Default phase if not set
    [ -z "$phase" ] && phase="unknown"

    # Still running?
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        log "$task_id: running (phase: $phase)"
        return 0
    fi

    # Process ended - handle based on phase
    case "$phase" in
        spawned|working)
            if [ -d "$worktree" ]; then
                local commits
                commits=$(cd "$worktree" && git log origin/master..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ' || echo "0")
                if [ "$commits" -gt 0 ]; then
                    log "$task_id: has $commits commit(s) - advancing to committed"
                    set_task_state "$task_id" "phase" "committed"
                    set_task_state "$task_id" "pid" ""
                    bd update "$task_id" --remove-label "phase:working" --add-label "phase:committed" 2>/dev/null || true
                else
                    log "$task_id: ended with no commits - checking for work"
                    local changes
                    changes=$(cd "$worktree" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ' || echo "0")
                    if [ "$changes" -gt 0 ]; then
                        log "$task_id: has uncommitted changes - respawning"
                        local subject
                        subject=$(bd show "$task_id" --json | jq -r '.title // .subject')
                        spawn_agent "$task_id" "$subject"
                    else
                        log "$task_id: no work done - marking blocked"
                        set_task_state "$task_id" "phase" "blocked"
                        set_task_state "$task_id" "pid" ""
                        bd update "$task_id" --remove-label "phase:working" --add-label "phase:blocked" 2>/dev/null || true
                    fi
                fi
            fi
            ;;
        committed)
            log "$task_id: pushing and creating PR"
            if ! dry "Would push and create PR for $task_id"; then
                (
                    cd "$worktree"
                    local branch
                    branch=$(get_task_field "$task_id" "branch")
                    git push -u origin "$branch" 2>/dev/null || true

                    local subject
                    subject=$(bd show "$task_id" --json | jq -r '.title // .subject')
                    local pr_url
                    pr_url=$(gh pr create --title "feat: $subject" --body "Implements $task_id" 2>/dev/null || echo "")

                    if [ -n "$pr_url" ]; then
                        local pr_num
                        pr_num=$(echo "$pr_url" | grep -oE '[0-9]+$' || echo "")
                        if [ -n "$pr_num" ]; then
                            set_task_state "$task_id" "pr_number" "$pr_num"
                            set_task_state "$task_id" "phase" "pr_created"
                            bd update "$task_id" --remove-label "phase:committed" --add-label "phase:pr_created" 2>/dev/null || true
                        fi
                    fi
                )
            fi
            ;;
        pr_created)
            local pr_num
            pr_num=$(get_task_field "$task_id" "pr_number")
            if [ -n "$pr_num" ]; then
                local state
                state=$(gh pr view "$pr_num" --json state -q .state 2>/dev/null || echo "")
                if [ "$state" = "MERGED" ]; then
                    log "$task_id: merged - closing"
                    set_task_state "$task_id" "phase" "merged"
                    bd update "$task_id" --remove-label "phase:pr_created" --add-label "phase:merged" 2>/dev/null || true
                    bd close "$task_id" 2>/dev/null || true
                    cleanup_worktree "$task_id"
                fi
            fi
            ;;
    esac
}

try_merge() {
    local task_id=$1

    local pr_num worktree
    pr_num=$(get_task_field "$task_id" "pr_number")
    worktree=$(get_task_field "$task_id" "worktree")

    [ -z "$pr_num" ] && return 0

    if dry "Would try to merge PR #$pr_num for $task_id"; then
        return 0
    fi

    local ready
    ready=$(gh pr view "$pr_num" --json mergeable,statusCheckRollup \
        --jq 'if .mergeable == "MERGEABLE" and (.statusCheckRollup == null or .statusCheckRollup.state == "SUCCESS" or (.statusCheckRollup | length) == 0) then "yes" else "no" end' 2>/dev/null || echo "no")

    if [ "$ready" = "yes" ]; then
        log "$task_id: merging PR #$pr_num"
        if gh pr merge "$pr_num" --squash --delete-branch 2>/dev/null; then
            set_task_state "$task_id" "phase" "merged"
            bd update "$task_id" --remove-label "phase:pr_created" --add-label "phase:merged" 2>/dev/null || true
            bd close "$task_id" 2>/dev/null || true
            cleanup_worktree "$task_id"
        fi
    else
        log "$task_id: PR #$pr_num not ready to merge"
    fi
}

cleanup_worktree() {
    local task_id=$1

    if dry "Would cleanup worktree for $task_id"; then
        return 0
    fi

    local worktree
    worktree=$(get_task_field "$task_id" "worktree")

    [ -d "$worktree" ] && git worktree remove "$worktree" --force 2>/dev/null || true
    git branch -d "agent/${task_id}" 2>/dev/null || true

    remove_task_state "$task_id"
}

# ============ MAIN LOOP ============
main() {
    init_state
    validate_epic

    $DRY_RUN && log "DRY RUN MODE - no changes will be made"
    log "Starting orchestrator (max $MAX_AGENTS agents)"

    mkdir -p "$WORKTREE_BASE"

    while true; do
        # Check active tasks
        local active_tasks
        active_tasks=$(get_active_tasks)

        echo "$active_tasks" | jq -c '.[]' 2>/dev/null | while read -r task; do
            [ -z "$task" ] || [ "$task" = "null" ] && continue

            local task_id
            task_id=$(echo "$task" | jq -r '.id')

            check_agent "$task_id"

            local phase
            phase=$(get_task_field "$task_id" "phase")
            if [ "$phase" = "pr_created" ]; then
                try_merge "$task_id"
            fi
        done

        # Spawn new agents if capacity available
        local active_count
        active_count=$(echo "$active_tasks" | jq 'length')

        if [ "$active_count" -lt "$MAX_AGENTS" ]; then
            local slots ready_tasks
            slots=$((MAX_AGENTS - active_count))
            ready_tasks=$(get_ready_tasks)

            echo "$ready_tasks" | jq -c '.[]' 2>/dev/null | head -n "$slots" | while read -r task; do
                [ -z "$task" ] || [ "$task" = "null" ] && continue

                local task_id subject
                task_id=$(echo "$task" | jq -r '.id')
                subject=$(echo "$task" | jq -r '.title // .subject')
                spawn_agent "$task_id" "$subject"
            done
        fi

        # Status report
        local ready_count
        ready_count=$(get_ready_tasks | jq 'length')
        active_count=$(get_active_tasks | jq 'length')
        log "Status: $active_count active, $ready_count ready"

        # Done?
        if [ "$active_count" -eq 0 ] && [ "$ready_count" -eq 0 ]; then
            log "All tasks complete!"
            break
        fi

        # In dry-run mode, exit after one iteration
        if $DRY_RUN; then
            log "Dry run complete - would continue polling every 30s"
            break
        fi

        sleep 30
    done
}

main

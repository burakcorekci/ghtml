# Parallel Orchestration Guide

This guide explains how to use the parallel orchestration system for executing multiple tasks concurrently using AI agents.

## Overview

The parallel orchestration system enables multiple AI agents to work on tasks concurrently using:
- **Beads** - Git-backed task queue with dependency tracking
- **Git worktrees** - Isolated working directories per agent
- **GitHub PRs** - Review gate and CI integration
- **Merger agent** - Automated PR review and merge

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR                              │
│  (Crash-resilient - reconstructs from Beads + local state)      │
├─────────────────────────────────────────────────────────────────┤
│   Beads ──▶ Worktree Spawner ──▶ Worker Agents ──▶ PRs          │
│     │         (parallel)            (parallel)       │           │
│     └───────────────────────────────────────────────▶ Merger    │
└─────────────────────────────────────────────────────────────────┘
```

### Components

1. **Orchestrator** (`scripts/orchestrate.sh`)
   - Polls Beads for ready tasks
   - Spawns worker agents in isolated worktrees
   - Monitors agent health via PID tracking
   - Respawns crashed agents

2. **Worker Agent** (`scripts/run-worker.sh` + `.claude/agents/worker.md`)
   - Receives task ID and works in isolated worktree
   - Follows TDD workflow
   - Creates PR when complete
   - Updates Beads with phase progress

3. **Merger Agent** (`scripts/run-merger.sh` + `.claude/agents/merger.md`)
   - Reviews PRs from worker agents
   - Checks CI status and mergeability
   - Auto-merges approved PRs
   - Cleans up worktrees and branches

## Prerequisites

- Beads CLI installed (`bd --version`)
- GitHub CLI installed (`gh --version`)
- Claude CLI available (`claude --version`)
- Git worktree support (Git 2.5+)

## Quick Start

```bash
# Initialize beads (first time only)
bd init

# Create tasks for an epic
bd create "Epic: Feature X" -p 0
# Note the epic ID, e.g., ghtml-a1b2

# Create child tasks
bd create "Implement component A" -p 1 --parent ghtml-a1b2
bd create "Implement component B" -p 1 --parent ghtml-a1b2
bd create "Write integration tests" -p 1 --parent ghtml-a1b2

# Run orchestrator
just orchestrate --epic ghtml-a1b2

# Check status
just orchestrate-status
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `just orchestrate` | Run for all ready tasks |
| `just orchestrate --epic X` | Run for specific epic |
| `just orchestrate --max-agents N` | Limit parallel agents (default: 4) |
| `just orchestrate --dry-run` | Preview what would happen |
| `just orchestrate-epic X` | Shorthand for `--epic` |
| `just orchestrate-status` | Show current orchestration state |
| `just orchestrate-preview` | Alias for `--dry-run` |
| `just orchestrate-help` | Show all orchestration commands |
| `just worker <task-id>` | Spawn single worker agent |
| `just merger` | Run merger to process PRs |
| `just merger --dry-run` | Preview merger actions |
| `just worktree-clean` | Remove all worktrees |
| `just worktree-remove <id>` | Remove specific worktree |
| `just test-crash-recovery` | Run crash recovery test suite |

## State Management

### Phase Tracking (Beads Labels)

Phase progress is tracked via Beads labels:
- `phase:spawned` - Worktree created, agent starting
- `phase:working` - Agent actively implementing
- `phase:committed` - Changes committed, ready for PR
- `phase:pr_created` - PR created, awaiting merge
- `phase:merged` - PR merged, task complete

Query tasks by phase:
```bash
bd list --json | jq '.[] | select(.labels[]? | contains("phase:working"))'
```

### Runtime State (Local File)

Runtime data that doesn't need to persist across machines is stored locally:
- **Location:** `.beads/orchestrator/state.json`
- **Contents:** PID, worktree path per task
- **Excluded from git:** via `.beads/.gitignore`

Example state file:
```json
{
  "ghtml-a1b2": {
    "pid": "12345",
    "worktree": "../worktrees/ghtml-a1b2",
    "pr_number": "42"
  }
}
```

## Monitoring Progress

### Status Overview
```bash
just orchestrate-status
```

Shows:
- Ready tasks (can be started)
- In-progress tasks (currently being worked)
- Active worktrees
- Open agent PRs

### Watch Mode
```bash
watch -n 5 'just orchestrate-status'
```

### Beads Queries
```bash
# Ready tasks (no blockers)
bd ready

# In-progress tasks
bd list --status in_progress

# All tasks as JSON
bd list --json
```

## Crash Recovery

The orchestrator is crash-resilient. If it stops unexpectedly:

1. **Check current state:**
   ```bash
   just orchestrate-status
   ```

2. **Restart orchestrator:**
   ```bash
   just orchestrate --epic <id>
   ```

The orchestrator will:
- Read in-progress tasks from Beads
- Check if agents are still running (via PID)
- Respawn crashed agents
- Continue where it left off

### Testing Recovery
```bash
just test-crash-recovery
```

Runs 7 test scenarios covering all recovery cases.

## Troubleshooting

### Agent Stuck

1. Check worktree for issues:
   ```bash
   cd ../worktrees/<task-id>
   git status
   ```

2. Check if agent process is running:
   ```bash
   # Get PID from state file
   jq '."<task-id>".pid' .beads/orchestrator/state.json

   # Check if running
   ps -p <pid>
   ```

3. Kill and respawn:
   ```bash
   kill <pid>
   just worker <task-id>
   ```

### Worktree Conflicts

```bash
# Force remove worktree
git worktree remove ../worktrees/<task-id> --force

# Remove branch
git branch -D agent/<task-id>

# Reset task to open status
bd update <task-id> --status open --remove-label "phase:working"
```

### PR Merge Conflicts

```bash
# In the worktree
cd ../worktrees/<task-id>
git fetch origin master
git rebase origin/master
git push --force-with-lease
```

### Beads State Issues

```bash
# View raw state
cat .beads/issues/*.jsonl | jq .

# Force sync
bd sync

# Run doctor
bd doctor
```

### Orphaned Worktrees

```bash
# List all worktrees
git worktree list

# Clean up orphans
just worktree-clean
```

## Best Practices

1. **Keep tasks small** - Easier for agents to complete successfully
2. **Clear dependencies** - Use `bd dep add` to link related tasks
3. **Monitor regularly** - Check status during long runs
4. **Review PRs** - Don't blindly trust automated merges
5. **Clean up** - Run `just worktree-clean` after completion
6. **Use dry-run** - Preview before running: `just orchestrate --dry-run`

## Limitations

- Agents may struggle with very complex tasks
- GitHub API rate limits apply for PR operations
- Worktrees use disk space (~50-100MB each)
- Maximum ~200 tasks per project (Beads limitation)
- Single machine execution (no distributed orchestration)

## Files Reference

| File | Purpose |
|------|---------|
| `scripts/orchestrate.sh` | Main orchestrator script |
| `scripts/run-worker.sh` | Worker agent spawner |
| `scripts/run-merger.sh` | Merger agent |
| `scripts/test-crash-recovery.sh` | Recovery test suite |
| `.claude/agents/worker.md` | Worker prompt template |
| `.claude/agents/merger.md` | Merger review guidelines |
| `.beads/orchestrator/state.json` | Local runtime state |

## Related Documentation

- `CLAUDE.md` - Entry point, execution mode selection
- `.claude/CODEBASE.md` - Architecture and module guide
- `.claude/specs/parallel_orchestrator/` - Specifications and research

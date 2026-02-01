# Task 005: Justfile Integration

## Description

Add orchestration commands to the project's justfile for easy invocation of the orchestrator, worker agents, and merger agent.

## Dependencies

- 002_core_orchestrator - Orchestrator script must exist
- 003_worker_agent - Worker agent must be configured
- 004_merger_agent - Merger agent must be configured

## Success Criteria

1. `just orchestrate` runs orchestrator for all tasks
2. `just orchestrate-epic <id>` runs for specific epic
3. `just worker <task-id>` spawns single worker
4. `just merger` runs merger agent
5. `just worktree-clean` cleans up worktrees
6. `just orchestrate-status` shows current state
7. All commands documented in justfile

## Implementation Steps

### 1. Read Current Justfile

Review existing justfile structure to maintain consistency.

### 2. Add Orchestration Commands

Add to `justfile`:

```makefile
# ==============================================================================
# Parallel Orchestration
# ==============================================================================

# Run parallel orchestrator for all ready tasks
orchestrate *args:
    ./scripts/orchestrate.sh {{args}}

# Run orchestrator for a specific epic
orchestrate-epic epic max_agents="4":
    ./scripts/orchestrate.sh --epic {{epic}} --max-agents {{max_agents}}

# Spawn a single worker agent for a task
worker task_id:
    ./scripts/run-worker.sh {{task_id}}

# Run the merger agent to process PRs
merger:
    ./scripts/run-merger.sh

# Show orchestration status from beads
orchestrate-status:
    @echo "=== Ready Tasks ==="
    @bd ready 2>/dev/null || echo "No ready tasks"
    @echo ""
    @echo "=== In Progress ==="
    @bd list --status in_progress 2>/dev/null || echo "None in progress"
    @echo ""
    @echo "=== Active Worktrees ==="
    @git worktree list | grep -v "$(pwd)" || echo "No worktrees"
    @echo ""
    @echo "=== Open Agent PRs ==="
    @gh pr list --json number,title,headRefName \
        --jq '.[] | select(.headRefName | startswith("agent/")) | "#\(.number): \(.title)"' \
        2>/dev/null || echo "No agent PRs"

# List available epics
epics:
    @echo "Available epics:"
    @bd list --json 2>/dev/null | jq -r '.issues[] | select(.id | contains(".") | not) | "  \(.id)\t\(.subject)"' || echo "  (none)"

# Clean up all worktrees
worktree-clean:
    @echo "Removing worktrees..."
    @git worktree list --porcelain | grep "worktree" | cut -d' ' -f2 | \
        grep -v "$(pwd)" | xargs -I{} git worktree remove {} --force 2>/dev/null || true
    @git worktree prune
    @echo "Done"

# Remove a specific worktree
worktree-remove task_id:
    git worktree remove "../worktrees/{{task_id}}" --force 2>/dev/null || true
    git branch -d "agent/{{task_id}}" 2>/dev/null || true

# Preview what orchestrator would do (dry run)
orchestrate-preview epic="":
    #!/bin/bash
    echo "=== Would Process ==="
    if [ -n "{{epic}}" ]; then
        bd ready --json | jq -r --arg e "{{epic}}" \
            '.issues[] | select(.id | startswith($e + ".")) | "  \(.id): \(.subject)"'
    else
        bd ready --json | jq -r '.issues[] | "  \(.id): \(.subject)"'
    fi
```

### 3. Add Help Documentation

Add help target that includes orchestration commands:

```makefile
# Show orchestration help
orchestrate-help:
    @echo "Parallel Orchestration Commands:"
    @echo ""
    @echo "  just orchestrate              Run orchestrator for all ready tasks"
    @echo "  just orchestrate --epic X     Run for specific epic"
    @echo "  just orchestrate-epic X       Shorthand for --epic"
    @echo "  just orchestrate-status       Show current orchestration state"
    @echo "  just orchestrate-preview      Preview what would run"
    @echo ""
    @echo "  just worker <task-id>         Spawn single worker agent"
    @echo "  just merger                   Run merger to process PRs"
    @echo ""
    @echo "  just epics                    List available epics"
    @echo "  just worktree-clean           Remove all worktrees"
    @echo "  just worktree-remove <id>     Remove specific worktree"
```

## Test Cases

### Test 1: Commands Parse
```bash
#!/bin/bash
# Verify all commands are recognized by just
just --list | grep -q "orchestrate" || exit 1
just --list | grep -q "worker" || exit 1
just --list | grep -q "merger" || exit 1
echo "PASS: commands recognized"
```

### Test 2: Status Command Works
```bash
#!/bin/bash
# Should run without error even if no tasks
just orchestrate-status > /dev/null 2>&1 || exit 1
echo "PASS: status command works"
```

### Test 3: Help Shows Commands
```bash
#!/bin/bash
just orchestrate-help | grep -q "orchestrate" || exit 1
echo "PASS: help shows commands"
```

## Verification Checklist

- [ ] `just orchestrate` works
- [ ] `just orchestrate --epic X` works
- [ ] `just orchestrate-epic X` works
- [ ] `just worker <id>` works
- [ ] `just merger` works
- [ ] `just orchestrate-status` shows state
- [ ] `just epics` lists epics
- [ ] `just worktree-clean` cleans up
- [ ] `just orchestrate-help` shows documentation
- [ ] Commands consistent with existing justfile style

## Notes

- Follow existing justfile conventions for variable naming
- Use `@` prefix for commands that shouldn't echo
- Consider adding tab completion hints
- Commands should fail gracefully if beads not initialized

## Files to Modify

- `justfile` - Add orchestration commands

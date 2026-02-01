# Task 007: Documentation

## Description

Update project documentation to include the parallel orchestration system. This includes updating CODEBASE.md, creating a usage guide, and ensuring all components are properly documented.

## Dependencies

- 006_crash_recovery_tests - System must be tested before documenting

## Success Criteria

1. CODEBASE.md updated with orchestration section
2. Usage guide created with examples
3. All scripts have header comments
4. Troubleshooting section included
5. Architecture diagram included

## Implementation Steps

### 1. Update CODEBASE.md

Add new section to `CODEBASE.md`:

```markdown
## Parallel Orchestration

The project supports parallel agent execution using Beads for task management,
git worktrees for isolation, and GitHub PRs for integration.

### Architecture

```
Beads (task queue) → Orchestrator → Worker Agents (parallel) → PRs → Merger Agent
```

### Quick Start

```bash
# Initialize beads (first time only)
bd init

# Create tasks for an epic
bd create "Epic: Feature X" -p 0
bd create "Task 1" -p 1 --parent <epic-id>
bd create "Task 2" -p 1 --parent <epic-id>

# Run orchestrator
just orchestrate --epic <epic-id>

# Or run specific components
just worker <task-id>    # Single worker
just merger              # Process PRs
```

### Commands

| Command | Description |
|---------|-------------|
| `just orchestrate` | Run for all ready tasks |
| `just orchestrate --epic X` | Run for specific epic |
| `just orchestrate-status` | Show current state |
| `just worker <id>` | Spawn single worker |
| `just merger` | Process PRs |
| `just worktree-clean` | Clean up worktrees |

### State Management

All orchestration state lives in Beads metadata:
- `meta.worktree` - Git worktree path
- `meta.branch` - Agent branch name
- `meta.agent_pid` - Process ID
- `meta.phase` - Current phase
- `meta.pr_number` - GitHub PR number

Query with: `bd list --json | jq '.issues[] | select(.status == "in_progress")'`
```

### 2. Expand Usage Guide

Expand `docs/orchestration.md` (stub already exists):

```markdown
# Parallel Orchestration Guide

## Overview

This guide explains how to use the parallel orchestration system for
executing multiple tasks concurrently using AI agents.

## Prerequisites

- Beads CLI installed (`bd --version`)
- GitHub CLI installed (`gh --version`)
- Claude CLI available

## Setup

### 1. Initialize Beads

```bash
bd init
```

### 2. Create an Epic and Tasks

```bash
# Create epic
bd create "Implement authentication" -p 0
# Note the epic ID, e.g., lt-a1b2

# Create tasks under epic
bd create "Add login endpoint" -p 1
bd dep add lt-a1b2.1 lt-a1b2    # Link to epic

bd create "Add logout endpoint" -p 1
bd dep add lt-a1b2.2 lt-a1b2

bd create "Add session middleware" -p 1
bd dep add lt-a1b2.3 lt-a1b2
bd dep add lt-a1b2.3 lt-a1b2.1  # Depends on login
```

### 3. View Task Graph

```bash
bd dep tree
```

## Running the Orchestrator

### Basic Usage

```bash
# Run for all ready tasks (max 4 parallel agents)
just orchestrate

# Run for specific epic
just orchestrate --epic lt-a1b2

# Adjust parallelism
just orchestrate --max-agents 6
```

### Monitoring Progress

```bash
# See current status
just orchestrate-status

# Watch beads state
watch -n 5 'bd list --status in_progress'

# Check agent logs
tail -f ../worktrees/*/agent.log
```

## Manual Operation

### Spawn Single Worker

```bash
just worker lt-a1b2.1
```

### Run Merger

```bash
just merger
```

### Clean Up

```bash
just worktree-clean
```

## Crash Recovery

The orchestrator is crash-resilient. If it stops:

1. Check current state: `just orchestrate-status`
2. Restart: `just orchestrate --epic <id>`

The orchestrator will:
- Detect in-progress tasks from Beads
- Check if agents are still running (via PID)
- Respawn crashed agents
- Continue where it left off

## Troubleshooting

### Agent Stuck

```bash
# Check agent log
cat ../worktrees/<task-id>/agent.log

# Kill and respawn
kill $(bd show <task-id> --json | jq -r '.meta.agent_pid')
just worker <task-id>
```

### Worktree Conflicts

```bash
# Force remove worktree
git worktree remove ../worktrees/<task-id> --force

# Reset task state
bd update <task-id> --status open --meta phase="" --meta worktree=""
```

### PR Merge Conflicts

```bash
# In the worktree
cd ../worktrees/<task-id>
git fetch origin main
git rebase origin/main
git push --force-with-lease
```

### Beads State Corruption

```bash
# View raw state
cat .beads/issues.jsonl | jq .

# Delete and recreate task
bd delete <task-id> --force
bd create "Task name" ...
```

## Best Practices

1. **Keep tasks small** - Easier for agents to complete
2. **Clear dependencies** - Use `bd dep add` to link related tasks
3. **Monitor regularly** - Check status during long runs
4. **Review PRs** - Don't blindly trust the merger
5. **Clean up** - Run `just worktree-clean` after completion

## Limitations

- Maximum ~200 tasks per project (Beads limitation)
- Agents may struggle with very complex tasks
- GitHub API rate limits apply
- Worktrees use disk space

## Architecture Reference

See `.claude/research/task_management_alternatives.md` for design decisions.
```

### 3. Add Script Headers

Ensure all scripts have documentation headers:

```bash
#!/bin/bash
# ==============================================================================
# orchestrate.sh - Parallel agent orchestration
#
# Usage: ./orchestrate.sh [OPTIONS]
#
# Options:
#   -e, --epic EPIC_ID    Only process tasks under this epic
#   -m, --max-agents N    Maximum parallel agents (default: 4)
#   -h, --help            Show this help
#
# Description:
#   Manages parallel execution of worker agents using Beads for task tracking
#   and git worktrees for isolation. Crash-resilient - can be restarted at
#   any time and will resume from current state.
#
# See: docs/parallel-orchestration.md
# ==============================================================================
```

## Test Cases

### Test 1: Documentation Links Valid
```bash
#!/bin/bash
# Check that referenced files exist
[ -f "CODEBASE.md" ] || exit 1
[ -f "docs/orchestration.md" ] || exit 1
echo "PASS: documentation files exist"
```

### Test 2: Commands Documented
```bash
#!/bin/bash
# Verify all just commands are documented
for cmd in orchestrate worker merger worktree-clean; do
    grep -q "$cmd" docs/orchestration.md || exit 1
done
echo "PASS: commands documented"
```

## Verification Checklist

- [ ] CODEBASE.md updated with orchestration section
- [ ] `docs/orchestration.md` expanded with full content
- [ ] All scripts have header comments
- [ ] Troubleshooting section covers common issues
- [ ] Architecture diagram included
- [ ] Examples are accurate and tested
- [ ] Links between docs are valid

## Notes

- Keep documentation concise - link to detailed docs where appropriate
- Include real command output examples where helpful
- Update docs if implementation changes

## Files to Modify

- `CODEBASE.md` - Add orchestration section
- `docs/orchestration.md` - Expand usage guide (stub exists)
- `scripts/orchestrate.sh` - Add header comments
- `scripts/run-worker.sh` - Add header comments
- `scripts/run-merger.sh` - Add header comments

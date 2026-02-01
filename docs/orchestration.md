# Parallel Orchestration Guide

> **Status:** This guide will be fully populated when the `parallel_orchestrator` epic is implemented. See `.plan/parallel_orchestrator/PLAN.md` for the implementation plan.

## Overview

The parallel orchestration system enables multiple AI agents to work on tasks concurrently using:
- **Beads** - Git-backed task queue with dependency tracking
- **Git worktrees** - Isolated working directories per agent
- **GitHub PRs** - Review gate and CI integration
- **Merger agent** - Automated PR review and merge

## Quick Start (Preview)

```bash
# Initialize beads (first time)
bd init

# Create tasks
bd create "Epic: My Feature" -p 0
bd create "Task 1" -p 1 --parent <epic-id>
bd create "Task 2" -p 1 --parent <epic-id>

# Run orchestrator
just orchestrate --epic <epic-id>

# Check status
just orchestrate-status
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR                              │
│  (Stateless - reconstructs from Beads each cycle)               │
├─────────────────────────────────────────────────────────────────┤
│   Beads ──▶ Worktree Spawner ──▶ Worker Agents ──▶ PRs          │
│     │                                  │                         │
│     └──────────────────────────────────┴───▶ Merger Agent       │
└─────────────────────────────────────────────────────────────────┘
```

## State Management

All orchestration state lives in Beads metadata:
- `meta.worktree` - Git worktree path
- `meta.branch` - Agent branch name
- `meta.agent_pid` - Process ID
- `meta.phase` - Current phase (spawned|working|committed|pr_created|merged)
- `meta.pr_number` - GitHub PR number

## Commands (Coming)

| Command | Description |
|---------|-------------|
| `just orchestrate` | Run for all ready tasks |
| `just orchestrate --epic X` | Run for specific epic |
| `just orchestrate-status` | Show current state |
| `just worker <id>` | Spawn single worker |
| `just merger` | Process PRs |
| `just worktree-clean` | Clean up worktrees |
| `just migrate-to-beads` | Migrate .plan/ tasks to Beads |

## Implementation Plan

See `.plan/parallel_orchestrator/` for full implementation details:
- `PLAN.md` - Epic overview and design
- `tasks/` - Individual task specifications

## Related Documentation

- `CLAUDE.md` - Entry point, execution mode selection
- `SUBAGENT.md` - Manual mode instructions
- `.plan/research/task_management_alternatives.md` - Research report

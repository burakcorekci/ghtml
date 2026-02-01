# Tasks

## Overview

This directory contains individual task specifications for the Parallel Orchestrator epic. Each task is designed to be independently executable once its dependencies are satisfied.

## Task Naming Convention

Tasks are named with a three-digit prefix followed by a descriptive name:
- `001_initialize_beads.md`
- `002_core_orchestrator.md`
- etc.

The numbering indicates a recommended execution order, though tasks 002-004 can be executed in parallel once 001 is complete.

## Task Status

| # | Task | Status | Notes |
|---|------|--------|-------|
| 001 | Initialize Beads | [ ] Pending | |
| 002 | Core Orchestrator | [ ] Pending | Can parallel with 003, 004 |
| 003 | Worker Agent | [ ] Pending | Can parallel with 002, 004 |
| 004 | Merger Agent | [ ] Pending | Can parallel with 002, 003 |
| 005 | Justfile Integration | [ ] Pending | |
| 006 | Crash Recovery Tests | [ ] Pending | |
| 007 | Documentation | [ ] Pending | |
| 008 | Migrate Existing Epics | [ ] Pending | |
| 009 | Cleanup Manual Mode | [ ] Pending | Final task |

Status legend:
- `[ ] Pending` - Not started
- `[~] In Progress` - Currently being worked on
- `[x] Complete` - Finished and verified
- `[!] Blocked` - Waiting on external dependency

## Execution Guidelines

1. **Check dependencies first** - Ensure all prerequisite tasks are complete
2. **Follow TDD** - Write tests before implementation (see CLAUDE.md)
3. **Verify success criteria** - All criteria must be met before marking complete
4. **Run full checks** - Use `just check` before marking complete
5. **Commit atomically** - Each task should result in a single commit

## Parallel Execution

After task 001 completes, tasks 002-004 can run in parallel:

```
001 ─────┬───────┬───────┐
         │       │       │
         ▼       ▼       ▼
       002     003     004
         │       │       │
         └───────┴───────┘
                 │
                 ▼
               005
                 │
                 ▼
               006
                 │
                 ▼
               007
                 │
                 ▼
               008
                 │
                 ▼
               009
```

## Adding New Tasks

1. Copy `000_template_task.md` from `../_template/tasks/`
2. Fill in all sections
3. Update this README with the new task
4. Update the parent PLAN.md task table and dependency graph

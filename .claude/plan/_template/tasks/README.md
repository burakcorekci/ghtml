# Tasks

## Overview

This directory contains individual task specifications for the epic. Each task is designed to be independently executable once its dependencies are satisfied.

## Task Naming Convention

Tasks are named with a three-digit prefix followed by a descriptive name:
- `001_first_task.md`
- `002_second_task.md`
- `003_third_task.md`

The numbering indicates a recommended execution order, though tasks can be executed in parallel if their dependencies are satisfied.

## Task Status

| # | Task | Status | Notes |
|---|------|--------|-------|
| 001 | [Task Name] | [ ] Pending | |
| 002 | [Task Name] | [ ] Pending | |
| 003 | [Task Name] | [ ] Pending | |

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

## Adding New Tasks

1. Copy `000_template_task.md` to `NNN_task_name.md`
2. Fill in all sections
3. Update this README with the new task
4. Update the parent PLAN.md task table and dependency graph

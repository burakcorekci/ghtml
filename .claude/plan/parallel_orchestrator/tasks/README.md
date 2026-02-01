# Tasks

## Overview

This directory contains individual task specifications for the Parallel Orchestrator epic. Each task is designed to be independently executable once its dependencies are satisfied.

**Key Conventions:**
- Task descriptions use EARS notation (WHEN/WHILE...THE...SHALL)
- Tasks link to requirements via `Implements` section
- Success criteria are testable EARS statements

## Task Naming Convention

Tasks are named with a three-digit prefix followed by a descriptive name:
- `001_initialize_beads.md`
- `001b_spec_structure_conventions.md`
- `002_core_orchestrator.md`

## Task Status

| # | Task | Status | Implements | Notes |
|---|------|--------|------------|-------|
| 001 | Initialize Beads | [x] Complete | REQ-001 | |
| 001b | Spec Structure Conventions | [x] Complete | REQ-006, REQ-007 | EARS, .specs/, justfile |
| 002 | Core Orchestrator | [x] Complete | REQ-001,002,003 | Can parallel with 003, 004 |
| 003 | Worker Agent | [x] Complete | REQ-002 | Can parallel with 002, 004 |
| 004 | Merger Agent | [x] Complete | REQ-005 | Can parallel with 002, 003 |
| 005 | Justfile Integration | [ ] Pending | - | |
| 006 | Crash Recovery Tests | [ ] Pending | REQ-003,004 | |
| 007 | Documentation | [ ] Pending | - | |
| 008 | Migrate Existing Epics | [ ] Pending | - | |
| 009 | Cleanup Manual Mode | [ ] Pending | - | Final task |

Status legend:
- `[ ] Pending` - Not started
- `[~] In Progress` - Currently being worked on
- `[x] Complete` - Finished and verified
- `[!] Blocked` - Waiting on external dependency

## Parallel Execution

After task 001b completes, tasks 002-004 can run in parallel:

```
001
 │
 ▼
001b ────┬───────┬───────┐
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

## Requirements Traceability

| Requirement | Tasks |
|-------------|-------|
| REQ-001: Task State Query | 001, 002 |
| REQ-002: Parallel Execution | 002, 003 |
| REQ-003: Crash Recovery | 002, 006 |
| REQ-004: Agent Crash Detection | 006 |
| REQ-005: PR Auto-Merge | 004 |
| REQ-006: Spec Discovery | 001b |
| REQ-007: State Single Source | 001b |

## Execution Guidelines

1. **Check dependencies first** - Ensure all prerequisite tasks are complete
2. **Read the spec** - Check `.specs/parallel_orchestrator/` for context
3. **Follow TDD** - Write tests before implementation
4. **Use EARS** - Success criteria should be testable EARS statements
5. **Verify success criteria** - All criteria must pass before marking complete
6. **Run full checks** - Use `just check` before marking complete
7. **Commit atomically** - Each task should result in a single commit

## Adding New Tasks

1. Copy from `../../_template/tasks/000_template_task.md`
2. Use EARS notation for description and success criteria
3. Add `Implements` section linking to requirements
4. Update this README with the new task
5. Update the parent PLAN.md task table

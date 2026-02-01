# Tasks

## Overview

This directory contains individual task specifications for the Learning Examples epic. Each task creates one example project demonstrating specific Lustre template features.

## Task Naming Convention

Tasks are named with a three-digit prefix:
- `001_rename_simple.md` - Rename existing example
- `002_attributes.md` - Attribute examples
- `003_events.md` - Event handler examples
- `004_control_flow.md` - Control flow examples
- `005_shoelace.md` - Shoelace web components
- `006_material_web.md` - Material Web components
- `007_tailwind.md` - Tailwind CSS
- `008_complete.md` - Combined example
- `009_ci_validation.md` - CI validation for examples

## Task Status

| # | Task | Status | Notes |
|---|------|--------|-------|
| 001 | Rename simple example | [x] Complete | |
| 002 | Create attributes example | [x] Complete | Depends on 001 |
| 003 | Create events example | [x] Complete | Depends on 001 |
| 004 | Create control flow example | [x] Complete | Depends on 001 |
| 005 | Create Shoelace example | [x] Complete | Depends on 001 |
| 006 | Create Material Web example | [x] Complete | Depends on 001 |
| 007 | Create Tailwind example | [x] Complete | Depends on 001 |
| 008 | Create complete example | [x] Complete | Depends on 002-007 |
| 009 | Add CI validation | [x] Complete | Depends on 001-008 |

Status legend:
- `[ ] Pending` - Not started
- `[~] In Progress` - Currently being worked on
- `[x] Complete` - Finished and verified
- `[!] Blocked` - Waiting on external dependency

## Execution Guidelines

1. **Check dependencies first** - Task 001 must be complete before starting 002-007
2. **Run template generator** - After creating `.lustre` files, run `just run` from project root
3. **Verify in browser** - Each example should work with `gleam run -m lustre/dev start`
4. **Test compilation** - All generated `.gleam` files must compile
5. **Commit atomically** - Each task should result in a single commit

## Parallel Execution

Tasks 002-007 can be executed in parallel after 001 is complete. Task 008 requires all previous tasks.

# Tasks

## Overview

This directory contains individual task specifications for the editor support epic. Each task is designed to be independently executable once its dependencies are satisfied.

## Task Naming Convention

Tasks are named with a three-digit prefix followed by a descriptive name:
- `001_directory_structure.md`
- `002_tree_sitter_grammar.md`
- `003_zed_extension.md`
- `004_textmate_grammar.md`
- `005_vscode_extension.md`

The numbering indicates priority order (tree-sitter > zed > textMate > vscode), though tasks can be executed in parallel if their dependencies are satisfied.

## Task Status

| # | Task | Status | Notes |
|---|------|--------|-------|
| 001 | Directory Structure | [ ] Pending | Foundation for all editor packages |
| 002 | Tree-sitter Grammar | [ ] Pending | Core grammar, highest priority |
| 003 | Zed Extension | [ ] Pending | Depends on tree-sitter |
| 004 | TextMate Grammar | [ ] Pending | Can run parallel to 002/003 |
| 005 | VS Code Extension | [ ] Pending | Depends on TextMate grammar |

Status legend:
- `[ ] Pending` - Not started
- `[~] In Progress` - Currently being worked on
- `[x] Complete` - Finished and verified
- `[!] Blocked` - Waiting on external dependency

## Dependency Graph

```
        001_directory_structure
               /          \
              v            v
002_tree_sitter_grammar   004_textmate_grammar
              |                    |
              v                    v
     003_zed_extension    005_vscode_extension
```

## Execution Guidelines

1. **Check dependencies first** - Ensure all prerequisite tasks are complete
2. **Test in target editor** - Verify highlighting works correctly
3. **Test with all fixtures** - Use files in `test/fixtures/` as test cases
4. **Commit atomically** - Each task should result in a single commit

## Adding New Tasks

1. Copy `000_template_task.md` to `NNN_task_name.md`
2. Fill in all sections
3. Update this README with the new task
4. Update the parent PLAN.md task table and dependency graph

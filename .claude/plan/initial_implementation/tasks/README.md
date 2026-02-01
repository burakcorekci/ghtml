# Implementation Tasks

## Overview

This directory contains 14 detailed tasks for implementing the Lustre Template Generator. Each task is designed to leave the application in a working state with passing tests.

## Task Dependency Graph

```
001_project_setup
       │
       ├──────────────────────────────────┐
       │                                  │
       v                                  v
002_types_module                   003_scanner_module
       │                                  │
       │                                  ├──────────────────────┐
       │                                  │                      │
       v                                  v                      v
005_parser_tokenizer            004_cache_module          012_orphan_cleanup ─┐
       │                              │                                       │
       v                              │                                       │
006_parser_ast_builder                │                                       │
       │                              │                                       │
       └──────────────┬───────────────┘                                       │
                      │                                                       │
                      v                                                       │
              007_codegen_basic                                               │
                      │                                                       │
                      v                                                       │
              008_codegen_attributes                                          │
                      │                                                       │
                      v                                                       │
              009_codegen_control_flow                                        │
                      │                                                       │
                      v                                                       │
              010_codegen_imports                                             │
                      │                                                       │
                      └──────────────┬────────────────────────────────────────┘
                                     │
                                     v
                              011_cli_basic
                                     │
                                     v
                              013_watch_mode
                                     │
                                     v
                              014_integration_testing
```

## Task Status

| # | Task | Status | Dependencies |
|---|------|--------|--------------|
| 001 | Project Setup | [x] Complete | None |
| 002 | Types Module | [x] Complete | 001 |
| 003 | Scanner Module | [x] Complete | 001 |
| 004 | Cache Module | [x] Complete | 001 |
| 005 | Parser Tokenizer | [x] Complete | 002 |
| 006 | Parser AST Builder | [x] Complete | 002, 005 |
| 007 | Codegen Basic | [x] Complete | 002, 004 |
| 008 | Codegen Attributes | [x] Complete | 007 |
| 009 | Codegen Control Flow | [x] Complete | 007, 008 |
| 010 | Codegen Imports | [x] Complete | 007, 009 |
| 011 | CLI Basic | [x] Complete | 003, 004, 006, 010 |
| 012 | Orphan Cleanup | [x] Complete | 003, 004 |
| 013 | Watch Mode | [x] Complete | 011, 012 |
| 014 | Integration Testing | [x] Complete | 011, 012, 013 |

Status legend:
- `[ ] Pending` - Not started
- `[~] In Progress` - Currently being worked on
- `[x] Complete` - Finished and verified
- `[!] Blocked` - Waiting on external dependency

## Task Summary

| # | Task | Description |
|---|------|-------------|
| 001 | Project Setup | Initialize Gleam project with dependencies |
| 002 | Types Module | Define all type definitions (Token, Node, etc.) |
| 003 | Scanner Module | File discovery and path utilities |
| 004 | Cache Module | Hash-based caching for regeneration |
| 005 | Parser Tokenizer | Convert template text to tokens |
| 006 | Parser AST Builder | Convert tokens to hierarchical AST |
| 007 | Codegen Basic | Generate code for elements and text |
| 008 | Codegen Attributes | Generate code for all attribute types |
| 009 | Codegen Control Flow | Generate code for if/each/case |
| 010 | Codegen Imports | Smart import management |
| 011 | CLI Basic | Main entry point and file generation |
| 012 | Orphan Cleanup | Remove generated files without sources |
| 013 | Watch Mode | File watching and auto-regeneration |
| 014 | Integration Testing | End-to-end tests and CI setup |

## Recommended Execution Order

For parallel development, these groups can be worked on simultaneously:

**Phase 1: Foundation** (Tasks 001-004)
```
001 → 002 → 005 → 006  (Parser track)
001 → 003              (Scanner track)
001 → 004              (Cache track)
```

**Phase 2: Code Generation** (Tasks 007-010)
```
007 → 008 → 009 → 010
```

**Phase 3: CLI & Integration** (Tasks 011-014)
```
011 → 012 → 013 → 014
```

## Testing Strategy

Each task includes:
- **Unit tests** in `test/<module>_test.gleam`
- **Success criteria** to verify completion
- **Verification checklist** for manual testing

Run tests after each task:
```bash
gleam test
gleam build
gleam run -m lustre_template_gen
```

## File Structure After Completion

```
lustre_template_gen/
├── src/
│   ├── lustre_template_gen.gleam      # CLI entry point
│   └── lustre_template_gen/
│       ├── types.gleam                 # Type definitions
│       ├── scanner.gleam               # File discovery
│       ├── cache.gleam                 # Hash caching
│       ├── parser.gleam                # Tokenizer + AST builder
│       ├── codegen.gleam               # Code generation
│       └── watcher.gleam               # Watch mode
├── test/
│   ├── lustre_template_gen_test.gleam
│   ├── types_test.gleam
│   ├── scanner_test.gleam
│   ├── cache_test.gleam
│   ├── parser_tokenizer_test.gleam
│   ├── parser_ast_test.gleam
│   ├── codegen_basic_test.gleam
│   ├── codegen_attributes_test.gleam
│   ├── codegen_control_flow_test.gleam
│   ├── codegen_imports_test.gleam
│   ├── cli_test.gleam
│   ├── orphan_cleanup_test.gleam
│   ├── watcher_test.gleam
│   ├── integration_test.gleam
│   └── fixtures/
│       ├── simple/
│       ├── attributes/
│       ├── control_flow/
│       └── complex/
└── gleam.toml
```

## Completion Checklist

- [x] 001: Project Setup
- [x] 002: Types Module
- [x] 003: Scanner Module
- [x] 004: Cache Module
- [x] 005: Parser Tokenizer
- [x] 006: Parser AST Builder
- [x] 007: Codegen Basic
- [x] 008: Codegen Attributes
- [x] 009: Codegen Control Flow
- [x] 010: Codegen Imports
- [x] 011: CLI Basic
- [x] 012: Orphan Cleanup
- [x] 013: Watch Mode
- [x] 014: Integration Testing

## Notes

- Follow TDD as specified in CLAUDE.md
- Each task should leave tests passing
- Use `.test/` directory for integration test files
- Keep the `.plan/` directory for reference but exclude from scanning

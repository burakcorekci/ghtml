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

## Task Summary

| # | Task | Description | Dependencies |
|---|------|-------------|--------------|
| 001 | Project Setup | Initialize Gleam project with dependencies | None |
| 002 | Types Module | Define all type definitions (Token, Node, etc.) | 001 |
| 003 | Scanner Module | File discovery and path utilities | 001 |
| 004 | Cache Module | Hash-based caching for regeneration | 001 |
| 005 | Parser Tokenizer | Convert template text to tokens | 002 |
| 006 | Parser AST Builder | Convert tokens to hierarchical AST | 002, 005 |
| 007 | Codegen Basic | Generate code for elements and text | 002, 004 |
| 008 | Codegen Attributes | Generate code for all attribute types | 007 |
| 009 | Codegen Control Flow | Generate code for if/each/case | 007, 008 |
| 010 | Codegen Imports | Smart import management | 007, 009 |
| 011 | CLI Basic | Main entry point and file generation | 003, 004, 006, 010 |
| 012 | Orphan Cleanup | Remove generated files without sources | 003, 004 |
| 013 | Watch Mode | File watching and auto-regeneration | 011, 012 |
| 014 | Integration Testing | End-to-end tests and CI setup | 011, 012, 013 |

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

- [ ] 001: Project Setup
- [ ] 002: Types Module
- [ ] 003: Scanner Module
- [ ] 004: Cache Module
- [ ] 005: Parser Tokenizer
- [ ] 006: Parser AST Builder
- [ ] 007: Codegen Basic
- [ ] 008: Codegen Attributes
- [ ] 009: Codegen Control Flow
- [ ] 010: Codegen Imports
- [ ] 011: CLI Basic
- [ ] 012: Orphan Cleanup
- [ ] 013: Watch Mode
- [ ] 014: Integration Testing

## Notes

- Follow TDD as specified in CLAUDE.md
- Each task should leave tests passing
- Use `.test/` directory for integration test files
- Keep the `.plan/` directory for reference but exclude from scanning

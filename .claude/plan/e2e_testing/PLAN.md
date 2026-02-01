# Epic: E2E Testing

## Goal

Add comprehensive end-to-end tests that verify generated `.gleam` code compiles in a real Lustre project and produces correct HTML output via SSR (Server-Side Rendering).

## Background

The current test suite validates parsing, AST generation, and code generation in isolation. While these unit tests verify correctness at each stage, they don't guarantee that the final generated code actually works in a real Lustre project. This epic adds E2E tests that:

1. Generate `.gleam` code from `.lustre` templates
2. Compile the generated code with `gleam build`
3. Render components using Lustre's `element.to_string()` SSR functionality
4. Verify the HTML output matches expectations

### Testing Pyramid

This epic establishes a clear testing pyramid:

```
           /\
          /  \  E2E: Build + SSR (high confidence, slow)
         /    \
        /------\  Integration: Error handling + edge cases
       /        \
      /----------\  Unit: parser, codegen, cache (fast, isolated)
```

## Scope

### In Scope
- Test directory restructure (unit/integration/e2e)
- E2E test infrastructure (temp directories, shell utilities)
- Project template fixture for compilation tests
- Build verification tests that run `gleam build` on generated code
- SSR tests using `element.to_string()` to verify HTML output
- Justfile integration with selective test commands
- Slimming down integration tests to remove redundancy

### Out of Scope
- Browser-based testing (Playwright, Cypress, etc.)
- Visual regression testing
- Performance benchmarks
- Testing against multiple Gleam/Lustre versions

## Design Overview

### Test Directory Structure

The test directory is organized by test type:

```
test/
├── unit/                         # Fast, isolated module tests
│   ├── scanner_test.gleam
│   ├── cli_test.gleam
│   ├── cache_test.gleam
│   ├── watcher_test.gleam
│   ├── types_test.gleam
│   ├── parser/
│   │   ├── tokenizer_test.gleam
│   │   └── ast_test.gleam
│   └── codegen/
│       ├── basic_test.gleam
│       ├── attributes_test.gleam
│       ├── control_flow_test.gleam
│       └── imports_test.gleam
├── integration/                  # Pipeline + error handling tests
│   └── pipeline_test.gleam
├── e2e/                          # Compilation + SSR tests
│   ├── helpers.gleam
│   ├── build_test.gleam
│   ├── ssr_test.gleam
│   └── project_template/         # Minimal Lustre project skeleton
│       ├── gleam.toml
│       └── src/
│           ├── main.gleam
│           └── types.gleam
└── fixtures/                     # Shared across all test types
    ├── simple/
    │   └── basic.lustre
    ├── attributes/
    │   └── all_attrs.lustre
    └── control_flow/
        └── full.lustre
```

### E2E Test Layers

```
                    ┌────────────────────────────────────────────┐
                    │            Layer 1: Build Tests            │
                    │  - Copy project template to temp dir       │
                    │  - Generate .gleam from shared fixtures    │
                    │  - Run `gleam build` and verify success    │
                    └────────────────────────────────────────────┘
                                         │
                                         ▼
                    ┌────────────────────────────────────────────┐
                    │            Layer 2: SSR Tests              │
                    │  - Use pre-generated test modules          │
                    │  - Call render() functions directly        │
                    │  - Verify HTML via element.to_string()     │
                    └────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Single Fixture Set**: E2E tests use existing `test/fixtures/` rather than creating duplicate fixtures. New fixtures are added there if needed.

2. **Selective Execution**: Justfile provides `just unit`, `just integration`, `just e2e` for running specific test types.

3. **Integration Test Scope**: After E2E tests exist, integration tests focus on error handling and edge cases only - not string pattern verification.

## Task Breakdown

| # | Task | Description | Dependencies |
|---|------|-------------|--------------|
| 000 | Test Restructure | Reorganize tests into unit/integration/e2e directories | None |
| 001 | E2E Test Infrastructure | Create test helpers, temp dir utilities | 000 |
| 002 | Project Template Fixture | Create minimal Lustre project skeleton for build tests | 001 |
| 003 | Fixture Enhancement | Add missing fixtures to test/fixtures/ for full coverage | 000 |
| 004 | Build Verification Tests | Tests that generate code and run `gleam build` | 001, 002, 003 |
| 005 | Add Lustre Dev Dependency | Add lustre to gleam.toml for SSR testing | None |
| 006 | SSR Test Modules | Pre-generate test modules for SSR tests | 003, 005 |
| 007 | SSR HTML Tests | Tests using element.to_string() to verify HTML | 005, 006 |
| 008 | Justfile Integration | Add e2e commands and update check workflow | 000, 004, 007 |
| 009 | Slim Integration Tests | Remove redundant string checks from pipeline_test | 007 |

## Task Dependency Graph

```
000_test_restructure ─────────────────┬──────────────────────────────┐
         │                            │                              │
         │                            ▼                              │
         │                   003_fixture_enhancement                 │
         │                            │                              │
         ▼                            │                              │
001_e2e_infrastructure                │                    005_lustre_dependency
         │                            │                              │
         ▼                            │                              │
002_project_template                  │                              │
         │                            │                              │
         └─────────┬──────────────────┘                              │
                   │                                                 │
                   ▼                                                 │
         004_build_tests                                             │
                   │              ┌──────────────────────────────────┘
                   │              │
                   │              ▼
                   │    006_ssr_test_modules
                   │              │
                   │              ▼
                   │    007_ssr_html_tests
                   │              │
                   └──────┬───────┤
                          │       │
                          ▼       │
               008_justfile_integration
                                  │
                                  ▼
                     009_slim_integration_tests
```

## Success Criteria

1. `just unit` runs fast unit tests
2. `just integration` runs integration tests
3. `just e2e` runs all E2E tests and passes
4. `just check` includes all test types and passes
5. Breaking a template intentionally causes E2E tests to fail
6. SSR tests verify actual HTML output from Lustre's `element.to_string()`
7. Integration tests focus on error handling, not string pattern verification
8. Shared fixtures cover the full range of template syntax features

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Lustre API changes break SSR tests | High | Pin Lustre version in dev-dependencies |
| Shell execution differs across platforms | Medium | Use Gleam's shellout or simplifile for cross-platform support |
| Temp directory cleanup fails | Low | Use try/finally patterns; add manual cleanup command |
| Build tests are slow | Medium | Run only on CI or via explicit command; parallelize where possible |
| Test restructure breaks imports | Medium | Use git mv to preserve history; verify all tests pass after move |

## Open Questions

- [x] Should E2E tests run in `just check` or only `just ci`? → Include in `just check`
- [x] Which Lustre version to pin? → Latest stable (will determine during task 005)
- [x] Should we create new E2E fixtures? → No, use existing `test/fixtures/` and enhance as needed

## References

- [Lustre element.to_string() API](https://hexdocs.pm/lustre/lustre/element.html#to_string)
- [Gleam testing documentation](https://gleam.run/documentation/guides/testing/)
- Existing test fixtures in `test/fixtures/`

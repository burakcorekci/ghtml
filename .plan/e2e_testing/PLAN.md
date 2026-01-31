# Epic: E2E Testing

## Goal

Add comprehensive end-to-end tests that verify generated `.gleam` code compiles in a real Lustre project and produces correct HTML output via SSR (Server-Side Rendering).

## Background

The current test suite validates parsing, AST generation, and code generation in isolation. While these unit tests verify correctness at each stage, they don't guarantee that the final generated code actually works in a real Lustre project. This epic adds E2E tests that:

1. Generate `.gleam` code from `.lustre` templates
2. Compile the generated code with `gleam build`
3. Render components using Lustre's `element.to_string()` SSR functionality
4. Verify the HTML output matches expectations

## Scope

### In Scope
- E2E test infrastructure (temp directories, shell utilities, fixture management)
- Project template fixture for compilation tests
- Template test fixtures covering all syntax features
- Build verification tests that run `gleam build` on generated code
- SSR tests using `element.to_string()` to verify HTML output
- Justfile integration with `just e2e` command

### Out of Scope
- Browser-based testing (Playwright, Cypress, etc.)
- Visual regression testing
- Performance benchmarks
- Testing against multiple Gleam/Lustre versions

## Design Overview

The E2E tests are organized in two layers:

```
                    ┌────────────────────────────────────────────┐
                    │            Layer 1: Build Tests            │
                    │  - Copy project template to temp dir       │
                    │  - Generate .gleam from .lustre fixtures   │
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

Test Structure:
test/
└── e2e/
    ├── helpers.gleam              # Temp dir, shell utilities
    ├── e2e_build_test.gleam       # Build verification tests
    ├── e2e_ssr_test.gleam         # SSR HTML tests
    ├── fixtures/
    │   ├── project_template/      # Minimal Lustre project
    │   │   ├── gleam.toml
    │   │   └── src/
    │   │       ├── main.gleam
    │   │       └── types.gleam
    │   └── templates/
    │       ├── basic.lustre
    │       ├── attributes.lustre
    │       ├── control_flow.lustre
    │       └── events.lustre
    └── generated/                 # Pre-generated SSR test modules
        └── .gitkeep
```

## Task Breakdown

| # | Task | Description | Dependencies |
|---|------|-------------|--------------|
| 001 | E2E Test Infrastructure | Create test helpers, temp dir utilities, fixture structure | None |
| 002 | Project Template Fixture | Create minimal Lustre project skeleton for build tests | 001 |
| 003 | Template Test Fixtures | Create .lustre fixtures covering all syntax features | 001 |
| 004 | Build Verification Tests | Tests that generate code and run `gleam build` | 001, 002, 003 |
| 005 | Add Lustre Dev Dependency | Add lustre to gleam.toml for SSR testing | None |
| 006 | SSR Test Modules | Pre-generate test modules for SSR tests | 003, 005 |
| 007 | SSR HTML Tests | Tests using element.to_string() to verify HTML | 005, 006 |
| 008 | Justfile Integration | Add e2e commands and update check workflow | 004, 007 |

## Task Dependency Graph

```
001_e2e_infrastructure ────────┬──────────────────────────────┐
         │                     │                              │
         ▼                     ▼                              ▼
002_project_template    003_template_fixtures         005_lustre_dependency
         │                     │                              │
         └─────────┬───────────┘                              │
                   │                                          │
                   ▼                                          │
         004_build_tests                                      │
                   │                                          │
                   │              ┌───────────────────────────┘
                   │              │
                   │              ▼
                   │    006_ssr_test_modules
                   │              │
                   │              ▼
                   │    007_ssr_html_tests
                   │              │
                   └──────┬───────┘
                          │
                          ▼
               008_justfile_integration
```

## Success Criteria

1. `just e2e` runs all E2E tests and passes
2. `just check` includes E2E tests and passes
3. Breaking a template intentionally causes E2E tests to fail
4. SSR tests verify actual HTML output from Lustre's `element.to_string()`
5. All fixtures cover the full range of template syntax features

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Lustre API changes break SSR tests | High | Pin Lustre version in dev-dependencies |
| Shell execution differs across platforms | Medium | Use Gleam's shellout or simplifile for cross-platform support |
| Temp directory cleanup fails | Low | Use try/finally patterns; add manual cleanup command |
| Build tests are slow | Medium | Run only on CI or via explicit command; parallelize where possible |

## Open Questions

- [x] Should E2E tests run in `just check` or only `just ci`? → Include in `just check`
- [x] Which Lustre version to pin? → Latest stable (will determine during task 005)

## References

- [Lustre element.to_string() API](https://hexdocs.pm/lustre/lustre/element.html#to_string)
- [Gleam testing documentation](https://gleam.run/documentation/guides/testing/)
- Existing test fixtures in `test/fixtures/`

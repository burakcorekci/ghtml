# Task 008: Justfile Integration

## Description

Add E2E test commands to the justfile and integrate them into the check and CI workflows. Task 000 establishes the basic `unit` and `integration` commands; this task adds `e2e` commands and updates workflows to include all test types.

## Dependencies

- 000_test_restructure - Provides `unit` and `integration` commands
- 004_build_verification_tests - Needs build tests to exist
- 007_ssr_html_tests - Needs SSR tests to exist

## Success Criteria

1. `just e2e` runs all E2E tests
2. `just e2e-build` runs only build verification tests
3. `just e2e-ssr` runs only SSR HTML tests
4. `just check` includes E2E tests
5. `just ci` includes E2E tests
6. Commands have helpful descriptions visible in `just --list`

## Implementation Steps

### 1. Add E2E Test Commands

Add the following to the Testing section in `justfile` (after the existing `unit` and `integration` commands from task 000):

```just
# Run E2E tests (slow - build verification + SSR)
e2e:
    gleam test test/e2e
    @echo "✓ E2E tests passed"

# Run only build verification tests
e2e-build:
    gleam test test/e2e/build_test.gleam
    @echo "✓ Build verification tests passed"

# Run only SSR HTML tests
e2e-ssr:
    gleam test test/e2e/ssr_test.gleam
    @echo "✓ SSR tests passed"
```

### 2. Update Check Workflow

Modify the `check` recipe to include E2E tests (task 000 adds unit/integration):

```just
# Run all quality checks (build → unit → integration → e2e → format → docs)
check:
    gleam build
    just unit
    just integration
    just e2e
    gleam format
    gleam docs build
    @echo "✓ All checks passed"
```

### 3. Update CI Workflow

Modify the `ci` recipe to include E2E tests:

```just
# Simulate CI pipeline (matches .github/workflows/test.yml)
ci:
    gleam build
    just unit
    just integration
    just e2e
    gleam format --check src test
    gleam docs build
    @echo "✓ CI simulation passed"
```

### 4. Remove integration-cli Recipe

Remove the `integration-cli` recipe from the justfile. E2E tests now provide the same CLI verification (generating code and verifying it works) with better coverage.

### 5. Add E2E Regeneration Command

Add command to regenerate SSR test modules from shared fixtures:

```just
# Regenerate E2E SSR test modules from shared fixtures
e2e-regen:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Regenerating E2E SSR test modules..."

    # Run generator on each fixture subdirectory
    for dir in test/fixtures/*/; do
        gleam run -m lustre_template_gen -- "$dir"
    done

    # Move generated files to e2e/generated
    find test/fixtures -name "*.gleam" -exec mv {} test/e2e/generated/ \;

    gleam format test/e2e/generated
    echo "✓ E2E SSR test modules regenerated"
```

### 6. Add Help Text

Update the justfile header to document E2E commands:

```just
# Lustre Template Generator - Development Commands
# Run `just` to see available commands
#
# Key workflows:
#   just check    - Run all quality checks before committing
#   just ci       - Simulate full CI pipeline
#   just e2e      - Run E2E tests only
#   just run      - Run the template generator
```

### 7. Organize Command Sections

Reorganize the justfile to group related commands:

```just
# === Workflows ===
# ... check, ci

# === CLI Execution ===
# ... run, run-force, run-watch, run-clean

# === Testing ===
# ... test-file, integration, e2e, e2e-build, e2e-ssr, e2e-regen

# === Examples ===
# ... examples, examples-clean

# === Planning ===
# ... epic

# === Utilities ===
# ... clean, g
```

## Test Cases

### Test 1: E2E Command Runs Tests

```bash
# Run e2e command and verify it executes
just e2e
# Should output: "✓ E2E tests passed"
```

### Test 2: Check Includes E2E

```bash
# Run check and verify e2e is included
just check
# Should see E2E test output in the flow
```

### Test 3: CI Includes E2E

```bash
# Run ci and verify e2e is included
just ci
# Should see E2E test output in the flow
```

### Test 4: Commands Appear in List

```bash
just --list
# Should show:
#   e2e         Run all E2E tests (build verification + SSR)
#   e2e-build   Run only build verification tests
#   e2e-ssr     Run only SSR HTML tests
#   e2e-regen   Regenerate E2E SSR test modules from fixtures
```

## Verification Checklist

- [ ] All implementation steps completed
- [ ] All test cases pass
- [ ] `just e2e` runs successfully
- [ ] `just e2e-build` runs build tests only
- [ ] `just e2e-ssr` runs SSR tests only
- [ ] `just check` includes E2E tests
- [ ] `just ci` includes E2E tests
- [ ] `integration-cli` recipe removed
- [ ] Commands are visible in `just --list`
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] No regressions in existing functionality

## Notes

- The `--only` flag for `gleam test` filters by test function name prefix
- E2E tests are slower than unit tests, so separate commands allow running them independently
- The regeneration command uses the template generator on the fixtures directory
- Consider adding a `just e2e-quick` command that skips build tests for faster iteration
- CI workflow should match what's defined in `.github/workflows/test.yml`
- Remove `integration-cli` recipe since e2e tests now provide the same verification (and more)

## Files to Modify

- `justfile` - Add E2E commands, remove `integration-cli`, update workflows
- `.github/workflows/test.yml` - Update if needed to match CI recipe

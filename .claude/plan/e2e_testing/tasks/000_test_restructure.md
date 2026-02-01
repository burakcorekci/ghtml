# Task 000: Test Directory Restructure

## Description

Restructure the test directory from a source-mirroring layout to a test-type-based layout (unit/integration/e2e). This establishes clear separation between fast unit tests, integration tests, and slower E2E tests, enabling selective test execution and optimized CI pipelines.

## Dependencies

- None - this is the prerequisite task for the entire epic.

## Success Criteria

1. Test files moved to `test/unit/`, `test/integration/`, `test/e2e/` directories
2. All existing tests pass after restructure
3. Justfile updated with `just unit`, `just integration`, `just e2e` commands
4. `just check` and `just ci` use the new commands
5. Shared fixtures remain at `test/fixtures/` (not moved)
6. Module imports updated to reflect new paths

## Implementation Steps

### 1. Create New Directory Structure

Create the target structure:

```
test/
├── unit/
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
├── integration/
│   └── pipeline_test.gleam
├── e2e/
│   └── .gitkeep
└── fixtures/              # unchanged
    ├── simple/
    ├── attributes/
    └── control_flow/
```

### 2. Move Unit Tests

Move all module-level tests:

```bash
# Create directories
mkdir -p test/unit/parser test/unit/codegen

# Move tests (preserving subdirectory structure)
mv test/lustre_template_gen/scanner_test.gleam test/unit/
mv test/lustre_template_gen/cli_test.gleam test/unit/
mv test/lustre_template_gen/cache_test.gleam test/unit/
mv test/lustre_template_gen/watcher_test.gleam test/unit/
mv test/lustre_template_gen/types_test.gleam test/unit/
mv test/lustre_template_gen/parser/*.gleam test/unit/parser/
mv test/lustre_template_gen/codegen/*.gleam test/unit/codegen/

# Remove empty directories
rm -rf test/lustre_template_gen
```

### 3. Move Integration Tests

Rename and move the integration test:

```bash
mkdir -p test/integration
mv test/integration_test.gleam test/integration/pipeline_test.gleam
```

### 4. Handle Root Test File

The `test/lustre_template_gen_test.gleam` file should be examined:
- If it contains tests, move to appropriate location
- If it's just a test entrypoint, remove it (gleeunit auto-discovers tests)

### 5. Update Module Imports

Update imports in moved files to reflect new paths:

**Before:** `import lustre_template_gen/parser/tokenizer`
**After:** `import lustre_template_gen/parser/tokenizer` (no change - source imports stay same)

Test file module paths change:
- `lustre_template_gen/parser/tokenizer_test` → `unit/parser/tokenizer_test`
- `lustre_template_gen/codegen/basic_test` → `unit/codegen/basic_test`
- `integration_test` → `integration/pipeline_test`

### 6. Update Justfile

Replace the testing section with:

```just
# === Testing ===

# Run all unit tests (fast)
unit:
    gleam test test/unit
    @echo "✓ Unit tests passed"

# Run Gleam integration tests
integration:
    gleam test test/integration
    @echo "✓ Integration tests passed"

# Run CLI smoke test (uses .test/ directory)
integration-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running CLI integration test..."
    TEST_DIR=".test/cli_integration"
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR/src"
    cat > "$TEST_DIR/gleam.toml" << 'EOF'
    name = "test_project"
    version = "0.1.0"
    target = "erlang"
    [dependencies]
    gleam_stdlib = ">= 0.34.0"
    EOF
    cat > "$TEST_DIR/src/test.lustre" << 'EOF'
    @params(name: String)
    <div class="greeting">{name}</div>
    EOF
    gleam run -m lustre_template_gen -- "$TEST_DIR"
    test -f "$TEST_DIR/src/test.gleam" || { echo "ERROR: test.gleam not generated"; exit 1; }
    grep -q "@generated" "$TEST_DIR/src/test.gleam" || { echo "ERROR: Missing @generated"; exit 1; }
    grep -q "pub fn render" "$TEST_DIR/src/test.gleam" || { echo "ERROR: Missing render"; exit 1; }
    echo "✓ CLI integration test passed"

# Run all tests
test: unit integration
    @echo "✓ All tests passed"

# Run a specific test file (e.g., just test-file tokenizer)
test-file name:
    gleam test -- --only {{name}}
```

Update the `check` recipe:

```just
# Run all quality checks (build → unit → integration → format → docs)
check:
    gleam build
    just unit
    just integration
    gleam format
    gleam docs build
    @echo "✓ All checks passed"
```

Update the `ci` recipe:

```just
# Simulate CI pipeline
ci:
    gleam build
    just unit
    just integration
    gleam format --check src test
    gleam docs build
    @echo "✓ CI simulation passed"
```

Note: The `integration-cli` recipe uses `.test/` for consistency. It will be removed in task 008 when e2e tests replace it.

### 7. Create E2E Directory Placeholder

```bash
mkdir -p test/e2e
touch test/e2e/.gitkeep
```

### 8. Verify All Tests Pass

```bash
just check
```

## Test Cases

### Test 1: Unit Tests Run

```bash
just unit
# Should run all tests in test/unit/ and pass
```

### Test 2: Integration Tests Run

```bash
just integration
# Should run tests in test/integration/ and pass
```

### Test 3: Full Check Passes

```bash
just check
# Should complete without errors
```

### Test 4: Commands Listed

```bash
just --list
# Should show unit, integration, e2e commands
```

## Verification Checklist

- [ ] All implementation steps completed
- [ ] All test cases pass
- [ ] `gleam build` succeeds
- [ ] `just unit` runs unit tests
- [ ] `just integration` runs integration tests
- [ ] `just check` passes
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] No regressions in existing functionality
- [ ] Old test directories removed
- [ ] Git tracks the moved files properly

## Notes

- Use `git mv` to preserve file history when moving tests
- The bash `integration` recipe is renamed to `integration-cli` and updated to use `.test/` for consistency
- `.test/` is the established convention for test artifacts (already gitignored)
- Fixtures stay at `test/fixtures/` since they're shared across test types
- E2E directory is created empty, to be populated by subsequent tasks
- Module paths in test files change but source imports remain the same
- The `integration-cli` recipe will be removed in task 008 when e2e tests replace it

## Files to Modify

- `test/unit/**` - Create directory and move unit tests
- `test/integration/**` - Create directory and move integration test
- `test/e2e/.gitkeep` - Create placeholder for E2E tests
- `justfile` - Update test commands
- Remove: `test/lustre_template_gen/` (after moving contents)
- Remove: `test/lustre_template_gen_test.gleam` (if just entrypoint)

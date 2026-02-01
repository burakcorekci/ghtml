# Task 004: Build Verification Tests

## Description

Create E2E tests that verify generated `.gleam` code actually compiles in a real Lustre project. These tests copy the project template to a temp directory, generate `.gleam` files from template fixtures, and run `gleam build` to verify the output is valid Gleam code.

## Dependencies

- 001_e2e_infrastructure - Needs temp dir and shell utilities
- 002_project_template_fixture - Needs the compilable project skeleton
- 003_template_test_fixtures - Needs the `.lustre` fixtures to generate from

## Success Criteria

1. `test/e2e/build_test.gleam` exists with build verification tests
2. Tests generate code from each fixture and verify compilation
3. All generated code compiles successfully with `gleam build`
4. Tests clean up temp directories after execution
5. Failure in one fixture doesn't block testing other fixtures

## Implementation Steps

### 1. Create Build Test Module

Create `test/e2e/build_test.gleam`:

```gleam
import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import simplifile
import lustre_template_gen
import lustre_template_gen/parser
import lustre_template_gen/codegen
import lustre_template_gen/cache
import e2e/helpers

/// Test that all template fixtures generate compilable code
pub fn all_fixtures_compile_test() {
  // Setup: create temp project
  let assert Ok(temp_dir) = helpers.create_temp_dir("build_test")
  let project_dir = temp_dir <> "/project"

  // Copy project template
  let assert Ok(Nil) = helpers.copy_directory(
    helpers.project_template_dir(),
    project_dir,
  )

  // Generate from all shared fixtures
  let assert Ok(fixtures) = simplifile.get_files(helpers.fixtures_dir())
  let lustre_files = list.filter(fixtures, fn(f) {
    string.ends_with(f, ".lustre")
  })

  // Generate each fixture
  list.each(lustre_files, fn(fixture_path) {
    let assert Ok(content) = simplifile.read(fixture_path)
    let assert Ok(template) = parser.parse(content)

    let filename = get_filename(fixture_path)
    let output_path = project_dir <> "/src/" <> filename <> ".gleam"
    let hash = cache.hash_content(content)
    let generated = codegen.generate(template, fixture_path, hash)

    let assert Ok(Nil) = simplifile.write(output_path, generated)
  })

  // Run gleam build
  let result = helpers.gleam_build(project_dir)

  // Cleanup
  let _ = helpers.cleanup_temp_dir(temp_dir)

  // Assert build succeeded
  result.exit_code
  |> should.equal(0)
}
```

### 2. Add Individual Fixture Tests

Add separate tests for each fixture for better error isolation:

```gleam
pub fn basic_fixture_compiles_test() {
  test_fixture_compiles("simple/basic")
}

pub fn attributes_fixture_compiles_test() {
  test_fixture_compiles("attributes/all_attrs")
}

pub fn control_flow_fixture_compiles_test() {
  test_fixture_compiles("control_flow/full")
}

pub fn events_fixture_compiles_test() {
  test_fixture_compiles("events/handlers")
}

pub fn fragments_fixture_compiles_test() {
  test_fixture_compiles("fragments/multiple_roots")
}

pub fn custom_elements_fixture_compiles_test() {
  test_fixture_compiles("custom_elements/web_components")
}

/// Helper to test a single fixture compiles
/// fixture_path is relative to test/fixtures/, e.g. "simple/basic"
fn test_fixture_compiles(fixture_rel_path: String) {
  let name = get_filename(fixture_rel_path)
  let assert Ok(temp_dir) = helpers.create_temp_dir(name <> "_test")
  let project_dir = temp_dir <> "/project"

  // Copy project template
  let assert Ok(Nil) = helpers.copy_directory(
    helpers.project_template_dir(),
    project_dir,
  )

  // Generate from fixture
  let fixture_path = helpers.fixtures_dir() <> "/" <> fixture_rel_path <> ".lustre"
  let assert Ok(content) = simplifile.read(fixture_path)
  let assert Ok(template) = parser.parse(content)

  let output_path = project_dir <> "/src/" <> name <> ".gleam"
  let hash = cache.hash_content(content)
  let generated = codegen.generate(template, fixture_path, hash)

  let assert Ok(Nil) = simplifile.write(output_path, generated)

  // Build
  let result = helpers.gleam_build(project_dir)

  // Cleanup
  let _ = helpers.cleanup_temp_dir(temp_dir)

  // Assert
  result.exit_code
  |> should.equal(0)
}
```

### 3. Add Error Case Tests

Test that intentionally broken templates fail to compile:

```gleam
pub fn invalid_gleam_fails_to_compile_test() {
  let assert Ok(temp_dir) = helpers.create_temp_dir("invalid_test")
  let project_dir = temp_dir <> "/project"

  // Copy template
  let assert Ok(Nil) = helpers.copy_directory(
    helpers.project_template_dir(),
    project_dir,
  )

  // Write invalid Gleam code
  let invalid_code = "
// This is intentionally invalid Gleam code
pub fn render() {
  undefined_function()  // This doesn't exist
}
"
  let assert Ok(Nil) = simplifile.write(
    project_dir <> "/src/invalid.gleam",
    invalid_code,
  )

  // Build should fail
  let result = helpers.gleam_build(project_dir)

  // Cleanup
  let _ = helpers.cleanup_temp_dir(temp_dir)

  // Assert build failed
  result.exit_code
  |> should.not_equal(0)
}
```

### 4. Add Filename Helper

```gleam
/// Extracts the filename without extension from a path
fn get_filename(path: String) -> String {
  path
  |> string.split("/")
  |> list.last()
  |> result.unwrap("unknown")
  |> string.replace(".lustre", "")
}
```

## Test Cases

### Test 1: All Fixtures Generate and Compile

The `all_fixtures_compile_test` function tests that all fixtures together form a valid project.

### Test 2: Individual Fixture Isolation

Each `*_fixture_compiles_test` function tests one fixture in isolation.

### Test 3: Invalid Code Detection

The `invalid_gleam_fails_to_compile_test` verifies the test harness correctly detects compilation failures.

## Verification Checklist

- [ ] All implementation steps completed
- [ ] All test cases pass
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] No regressions in existing functionality
- [ ] Temp directories are cleaned up after tests
- [ ] Tests run in reasonable time (<30s each)

## Notes

- Tests may be slow due to `gleam build` invocations - consider running only in CI
- Each test creates its own temp directory for isolation
- Cleanup is attempted even on test failure using `let _ =` pattern
- The project template must have all necessary types already defined
- Generated code is placed in `src/` alongside `main.gleam` and `types.gleam`

## Files to Modify

- `test/e2e/build_test.gleam` - Create build verification test module

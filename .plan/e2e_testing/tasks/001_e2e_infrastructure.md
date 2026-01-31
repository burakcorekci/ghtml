# Task 001: E2E Test Infrastructure

## Description

Create the foundational infrastructure for E2E testing, including helper modules for temporary directory management, shell command execution, and the fixture directory structure.

## Dependencies

- None - this is the first task.

## Success Criteria

1. `test/e2e/helpers.gleam` module exists with temp directory utilities
2. `test/e2e/fixtures/` directory structure is created
3. Helper functions for shell execution are working
4. All helper functions have corresponding tests

## Implementation Steps

### 1. Create E2E Directory Structure

Create the following directory structure:

```
test/
└── e2e/
    ├── helpers.gleam
    └── fixtures/
        ├── project_template/
        │   └── .gitkeep
        ├── templates/
        │   └── .gitkeep
        └── generated/
            └── .gitkeep
```

### 2. Implement Temp Directory Helpers

Create `test/e2e/helpers.gleam` with utilities for:

```gleam
import gleam/result
import simplifile

/// Creates a temporary directory for E2E testing
/// Returns the path to the created directory
pub fn create_temp_dir(prefix: String) -> Result(String, simplifile.FileError) {
  let base = "/tmp/lustre_template_gen_e2e"
  let timestamp = get_timestamp()
  let path = base <> "/" <> prefix <> "_" <> timestamp

  use _ <- result.try(simplifile.create_directory_all(path))
  Ok(path)
}

/// Removes a temporary directory and all its contents
pub fn cleanup_temp_dir(path: String) -> Result(Nil, simplifile.FileError) {
  simplifile.delete(path)
}

/// Copies a directory recursively
pub fn copy_directory(src: String, dest: String) -> Result(Nil, simplifile.FileError) {
  simplifile.copy_directory(src, dest)
}
```

### 3. Implement Shell Execution Helper

Add shell command execution for running `gleam build`:

```gleam
import gleam/erlang/os
import gleam/string

/// Result of a shell command execution
pub type CommandResult {
  CommandResult(exit_code: Int, stdout: String, stderr: String)
}

/// Executes a shell command in the given directory
pub fn run_command(
  command: String,
  args: List(String),
  cwd: String,
) -> CommandResult {
  // Use Erlang's os:cmd or shellout library
  // Return exit code, stdout, and stderr
}

/// Runs `gleam build` in the specified directory
pub fn gleam_build(project_dir: String) -> CommandResult {
  run_command("gleam", ["build"], project_dir)
}
```

### 4. Add Fixture Path Helpers

```gleam
/// Returns the path to the E2E fixtures directory
pub fn fixtures_dir() -> String {
  "test/e2e/fixtures"
}

/// Returns the path to the project template fixture
pub fn project_template_dir() -> String {
  fixtures_dir() <> "/project_template"
}

/// Returns the path to the template fixtures directory
pub fn templates_dir() -> String {
  fixtures_dir() <> "/templates"
}

/// Returns the path to the generated modules directory
pub fn generated_dir() -> String {
  fixtures_dir() <> "/generated"
}
```

## Test Cases

### Test 1: Temp Directory Creation and Cleanup

```gleam
pub fn temp_dir_lifecycle_test() {
  // Create temp dir
  let assert Ok(path) = helpers.create_temp_dir("test")

  // Verify it exists
  let assert Ok(True) = simplifile.is_directory(path)

  // Cleanup
  let assert Ok(Nil) = helpers.cleanup_temp_dir(path)

  // Verify it's gone
  let assert Ok(False) = simplifile.is_directory(path)
}
```

### Test 2: Directory Copy

```gleam
pub fn copy_directory_test() {
  let assert Ok(temp) = helpers.create_temp_dir("copy_test")
  let src = temp <> "/src"
  let dest = temp <> "/dest"

  // Create source with file
  let assert Ok(Nil) = simplifile.create_directory(src)
  let assert Ok(Nil) = simplifile.write(src <> "/test.txt", "hello")

  // Copy
  let assert Ok(Nil) = helpers.copy_directory(src, dest)

  // Verify
  let assert Ok("hello") = simplifile.read(dest <> "/test.txt")

  // Cleanup
  let assert Ok(Nil) = helpers.cleanup_temp_dir(temp)
}
```

### Test 3: Fixture Path Resolution

```gleam
pub fn fixture_paths_test() {
  helpers.fixtures_dir()
  |> should.equal("test/e2e/fixtures")

  helpers.project_template_dir()
  |> should.equal("test/e2e/fixtures/project_template")

  helpers.templates_dir()
  |> should.equal("test/e2e/fixtures/templates")
}
```

## Verification Checklist

- [ ] All implementation steps completed
- [ ] All test cases pass
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] No regressions in existing functionality
- [ ] Directory structure matches specification

## Notes

- Using `simplifile` for file operations as it's already a project dependency
- Timestamp generation uses Erlang's monotonic time for uniqueness
- Shell execution may need platform-specific handling (Unix vs Windows)
- The generated/ directory is for pre-generated SSR test modules (task 006)

## Files to Modify

- `test/e2e/helpers.gleam` - Create new module with utility functions
- `test/e2e/helpers_test.gleam` - Create tests for helpers
- `test/e2e/fixtures/.gitkeep` files - Create placeholder files for git tracking

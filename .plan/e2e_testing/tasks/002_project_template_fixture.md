# Task 002: Project Template Fixture

## Description

Create a minimal Lustre project skeleton that can be used as a base for E2E build tests. This fixture will be copied to a temp directory, have generated `.gleam` files added to it, and then compiled with `gleam build` to verify the generated code is valid.

## Dependencies

- 001_e2e_infrastructure - Needs fixture directory structure and copy utilities

## Success Criteria

1. Project template exists at `test/e2e/fixtures/project_template/`
2. Template includes valid `gleam.toml` with Lustre dependency
3. Template includes `src/main.gleam` as entry point
4. Template includes `src/types.gleam` with common test types
5. Template compiles successfully with `gleam build`

## Implementation Steps

### 1. Create gleam.toml

Create `test/e2e/fixtures/project_template/gleam.toml`:

```toml
name = "e2e_test_project"
version = "0.1.0"
target = "erlang"

[dependencies]
gleam_stdlib = ">= 0.44.0 and < 2.0.0"
lustre = ">= 4.0.0 and < 5.0.0"
```

Note: The Lustre version should match what's added in task 005.

### 2. Create Main Module

Create `test/e2e/fixtures/project_template/src/main.gleam`:

```gleam
//// Entry point for E2E test project
//// This module exists to make the project compilable

import gleam/io

pub fn main() {
  io.println("E2E test project")
}
```

### 3. Create Types Module

Create `test/e2e/fixtures/project_template/src/types.gleam`:

```gleam
//// Common types used in E2E test templates
//// These types are referenced by the template fixtures

/// A sample user type for testing
pub type User {
  User(name: String, email: String, is_admin: Bool, role: Role)
}

/// Role variants for case expression testing
pub type Role {
  Admin
  Member(since: Int)
  Guest
}

/// Status variants for testing
pub type Status {
  Active
  Inactive
  Pending
}

/// Creates a sample user for testing
pub fn sample_user() -> User {
  User(
    name: "Test User",
    email: "test@example.com",
    is_admin: False,
    role: Member(2024),
  )
}

/// Creates an admin user for testing
pub fn admin_user() -> User {
  User(
    name: "Admin User",
    email: "admin@example.com",
    is_admin: True,
    role: Admin,
  )
}
```

### 4. Verify Template Compiles

The project template should be able to compile on its own (without generated files):

```bash
cd test/e2e/fixtures/project_template
gleam build
```

### 5. Add .gitignore

Create `test/e2e/fixtures/project_template/.gitignore`:

```
/build
/erl_crash.dump
```

## Test Cases

### Test 1: Project Template Exists

```gleam
pub fn project_template_exists_test() {
  let path = helpers.project_template_dir()

  // Verify gleam.toml exists
  let assert Ok(True) = simplifile.is_file(path <> "/gleam.toml")

  // Verify src directory exists
  let assert Ok(True) = simplifile.is_directory(path <> "/src")

  // Verify main.gleam exists
  let assert Ok(True) = simplifile.is_file(path <> "/src/main.gleam")

  // Verify types.gleam exists
  let assert Ok(True) = simplifile.is_file(path <> "/src/types.gleam")
}
```

### Test 2: Project Template Compiles

```gleam
pub fn project_template_compiles_test() {
  // Copy template to temp dir
  let assert Ok(temp) = helpers.create_temp_dir("compile_test")
  let project_dir = temp <> "/project"

  let assert Ok(Nil) = helpers.copy_directory(
    helpers.project_template_dir(),
    project_dir,
  )

  // Run gleam build
  let result = helpers.gleam_build(project_dir)

  // Cleanup
  let assert Ok(Nil) = helpers.cleanup_temp_dir(temp)

  // Verify success
  result.exit_code |> should.equal(0)
}
```

### Test 3: Types Module Has Required Types

```gleam
pub fn types_module_content_test() {
  let path = helpers.project_template_dir() <> "/src/types.gleam"
  let assert Ok(content) = simplifile.read(path)

  // Verify required types exist
  content |> string.contains("type User") |> should.be_true()
  content |> string.contains("type Role") |> should.be_true()
  content |> string.contains("type Status") |> should.be_true()
  content |> string.contains("Admin") |> should.be_true()
  content |> string.contains("Member") |> should.be_true()
}
```

## Verification Checklist

- [ ] All implementation steps completed
- [ ] All test cases pass
- [ ] `gleam build` succeeds on project template
- [ ] `gleam test` passes
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] No regressions in existing functionality
- [ ] Types module provides all types needed by template fixtures

## Notes

- The project template is intentionally minimal - just enough to compile generated code
- Types are designed to match what the template fixtures (task 003) will use
- The template uses the same Lustre version that will be added to the main project
- Generated files will be copied to `src/` directory alongside main.gleam

## Files to Modify

- `test/e2e/fixtures/project_template/gleam.toml` - Create project config
- `test/e2e/fixtures/project_template/src/main.gleam` - Create entry point
- `test/e2e/fixtures/project_template/src/types.gleam` - Create common types
- `test/e2e/fixtures/project_template/.gitignore` - Ignore build artifacts

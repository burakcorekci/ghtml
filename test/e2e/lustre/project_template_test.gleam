//// Tests for the project template fixture.
////
//// Verifies that the project template:
//// - Exists with all required files
//// - Compiles successfully with `gleam build`
//// - Contains required types for E2E testing

import e2e_helpers
import gleam/string
import gleeunit/should
import simplifile

// === Project Template Existence Tests ===

pub fn project_template_exists_test() {
  let path = e2e_helpers.project_template_dir()

  // Verify gleam.toml exists
  let assert Ok(True) = simplifile.is_file(path <> "/gleam.toml")

  // Verify src directory exists
  let assert Ok(True) = simplifile.is_directory(path <> "/src")

  // Verify main.gleam exists
  let assert Ok(True) = simplifile.is_file(path <> "/src/main.gleam")

  // Verify types.gleam exists
  let assert Ok(True) = simplifile.is_file(path <> "/src/types.gleam")
}

pub fn project_template_gleam_toml_valid_test() {
  let path = e2e_helpers.project_template_dir() <> "/gleam.toml"
  let assert Ok(content) = simplifile.read(path)

  // Verify required fields
  content |> string.contains("name = \"e2e_test_project\"") |> should.be_true()
  content |> string.contains("gleam_stdlib") |> should.be_true()
  content |> string.contains("lustre") |> should.be_true()
}

// === Project Template Compilation Test ===

pub fn project_template_compiles_test() {
  // Copy template to temp dir
  let assert Ok(temp) = e2e_helpers.create_temp_dir("compile_test")
  let project_dir = temp <> "/project"

  let assert Ok(Nil) =
    e2e_helpers.copy_directory(e2e_helpers.project_template_dir(), project_dir)

  // Run gleam build
  let result = e2e_helpers.gleam_build(project_dir)

  // Cleanup
  let assert Ok(Nil) = e2e_helpers.cleanup_temp_dir(temp)

  // Verify success
  result.exit_code |> should.equal(0)
}

// === Types Module Content Test ===

pub fn types_module_content_test() {
  let path = e2e_helpers.project_template_dir() <> "/src/types.gleam"
  let assert Ok(content) = simplifile.read(path)

  // Verify required types exist
  content |> string.contains("type User") |> should.be_true()
  content |> string.contains("type Role") |> should.be_true()
  content |> string.contains("type Status") |> should.be_true()
  content |> string.contains("Admin") |> should.be_true()
  content |> string.contains("Member") |> should.be_true()
}

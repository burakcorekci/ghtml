//// Build verification tests for generated Gleam code.
////
//// These tests verify that code generated from `.ghtml` template fixtures
//// actually compiles in a real Lustre project. Each test:
//// 1. Creates a temp directory
//// 2. Copies the project template
//// 3. Generates `.gleam` code from fixtures
//// 4. Runs `gleam build` to verify compilation
//// 5. Cleans up the temp directory

import e2e_helpers
import ghtml/cache
import ghtml/codegen
import ghtml/parser
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import simplifile

// === Helper Functions ===

/// Extracts the filename without extension from a path
fn get_filename(path: String) -> String {
  path
  |> string.split("/")
  |> list.last()
  |> result.unwrap("unknown")
  |> string.replace(".ghtml", "")
}

/// Helper to test a single fixture compiles
/// fixture_path is relative to test/fixtures/, e.g. "simple/basic"
fn test_fixture_compiles(fixture_rel_path: String) {
  let name = get_filename(fixture_rel_path)
  let assert Ok(temp_dir) = e2e_helpers.create_temp_dir(name <> "_test")
  let project_dir = temp_dir <> "/project"

  // Copy project template
  let assert Ok(Nil) =
    e2e_helpers.copy_directory(e2e_helpers.project_template_dir(), project_dir)

  // Generate from fixture
  let fixture_path =
    e2e_helpers.fixtures_dir() <> "/" <> fixture_rel_path <> ".ghtml"
  let assert Ok(content) = simplifile.read(fixture_path)
  let assert Ok(template) = parser.parse(content)

  let output_path = project_dir <> "/src/" <> name <> ".gleam"
  let hash = cache.hash_content(content)
  let generated = codegen.generate(template, fixture_path, hash)

  let assert Ok(Nil) = simplifile.write(output_path, generated)

  // Build
  let result = e2e_helpers.gleam_build(project_dir)

  // Cleanup only on success to allow debugging
  case result.exit_code {
    0 -> {
      let _ = e2e_helpers.cleanup_temp_dir(temp_dir)
      Nil
    }
    _ -> {
      // Print debug info on failure
      io.println("Build failed for: " <> fixture_rel_path)
      io.println("Temp dir: " <> temp_dir)
      io.println("Stderr: " <> result.stderr)
      io.println("Stdout: " <> result.stdout)
      Nil
    }
  }

  // Assert
  result.exit_code
  |> should.equal(0)
}

// === All Fixtures Combined Test ===

/// Test that all template fixtures generate compilable code when combined
pub fn all_fixtures_compile_test() {
  // Setup: create temp project
  let assert Ok(temp_dir) = e2e_helpers.create_temp_dir("build_test")
  let project_dir = temp_dir <> "/project"

  // Copy project template
  let assert Ok(Nil) =
    e2e_helpers.copy_directory(e2e_helpers.project_template_dir(), project_dir)

  // Get all .ghtml fixtures
  let assert Ok(fixtures) = simplifile.get_files(e2e_helpers.fixtures_dir())
  let lustre_files =
    list.filter(fixtures, fn(f) { string.ends_with(f, ".ghtml") })

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
  let result = e2e_helpers.gleam_build(project_dir)

  // Debug on failure
  case result.exit_code {
    0 -> {
      let _ = e2e_helpers.cleanup_temp_dir(temp_dir)
      Nil
    }
    _ -> {
      io.println("Build failed in all_fixtures_compile_test")
      io.println("Temp dir: " <> temp_dir)
      io.println("Stderr: " <> result.stderr)
      Nil
    }
  }

  // Assert build succeeded
  result.exit_code
  |> should.equal(0)
}

// === Individual Fixture Tests ===

pub fn basic_fixture_compiles_test() {
  test_fixture_compiles("simple/basic")
}

pub fn attributes_fixture_compiles_test() {
  test_fixture_compiles("attributes/all_attrs")
}

pub fn control_flow_fixture_compiles_test() {
  test_fixture_compiles("control_flow/full")
}

pub fn fragments_fixture_compiles_test() {
  test_fixture_compiles("fragments/multiple_roots")
}

pub fn custom_elements_fixture_compiles_test() {
  test_fixture_compiles("custom_elements/web_components")
}

pub fn edge_cases_fixture_compiles_test() {
  test_fixture_compiles("edge_cases/special")
}

// === Error Case Test ===

/// Test that intentionally broken templates fail to compile
pub fn invalid_gleam_fails_to_compile_test() {
  let assert Ok(temp_dir) = e2e_helpers.create_temp_dir("invalid_test")
  let project_dir = temp_dir <> "/project"

  // Copy template
  let assert Ok(Nil) =
    e2e_helpers.copy_directory(e2e_helpers.project_template_dir(), project_dir)

  // Write invalid Gleam code
  let invalid_code =
    "
// This is intentionally invalid Gleam code
pub fn render() {
  undefined_function()  // This doesn't exist
}
"
  let assert Ok(Nil) =
    simplifile.write(project_dir <> "/src/invalid.gleam", invalid_code)

  // Build should fail
  let result = e2e_helpers.gleam_build(project_dir)

  // Cleanup
  let _ = e2e_helpers.cleanup_temp_dir(temp_dir)

  // Assert build failed
  result.exit_code
  |> should.not_equal(0)
}

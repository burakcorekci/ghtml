//// Tests for E2E test helper utilities.
////
//// These tests verify the helper functions used by E2E tests for:
//// - Temporary directory management
//// - Shell command execution
//// - Path resolution

import e2e_helpers
import gleam/string
import gleeunit/should
import simplifile

// === Temp Directory Tests ===

pub fn create_temp_dir_creates_directory_test() {
  // Create a temp directory with a prefix
  let assert Ok(path) = e2e_helpers.create_temp_dir("test")

  // Verify it exists and is a directory
  let assert Ok(True) = simplifile.is_directory(path)

  // Verify path format (should be in .test/ directory)
  should.be_true(string.starts_with(path, ".test/e2e_test_"))

  // Cleanup
  let assert Ok(Nil) = e2e_helpers.cleanup_temp_dir(path)
}

pub fn create_temp_dir_unique_paths_test() {
  // Create two temp directories
  let assert Ok(path1) = e2e_helpers.create_temp_dir("unique")
  let assert Ok(path2) = e2e_helpers.create_temp_dir("unique")

  // Paths should be different (timestamps make them unique)
  should.not_equal(path1, path2)

  // Both should exist
  let assert Ok(True) = simplifile.is_directory(path1)
  let assert Ok(True) = simplifile.is_directory(path2)

  // Cleanup
  let assert Ok(Nil) = e2e_helpers.cleanup_temp_dir(path1)
  let assert Ok(Nil) = e2e_helpers.cleanup_temp_dir(path2)
}

pub fn cleanup_temp_dir_removes_contents_test() {
  // Create temp dir with files inside
  let assert Ok(path) = e2e_helpers.create_temp_dir("cleanup")
  let file_path = path <> "/test_file.txt"
  let assert Ok(Nil) = simplifile.write(file_path, "test content")

  // Verify file exists
  let assert Ok(True) = simplifile.is_file(file_path)

  // Cleanup should remove everything
  let assert Ok(Nil) = e2e_helpers.cleanup_temp_dir(path)

  // Verify directory is gone
  let assert Ok(False) = simplifile.is_directory(path)
}

pub fn temp_dir_lifecycle_test() {
  // Full lifecycle test
  let assert Ok(path) = e2e_helpers.create_temp_dir("lifecycle")

  // Verify it exists
  let assert Ok(True) = simplifile.is_directory(path)

  // Cleanup
  let assert Ok(Nil) = e2e_helpers.cleanup_temp_dir(path)

  // Verify it's gone
  let assert Ok(False) = simplifile.is_directory(path)
}

// === Directory Copy Tests ===

pub fn copy_directory_copies_files_test() {
  let assert Ok(temp) = e2e_helpers.create_temp_dir("copy_test")
  let src = temp <> "/src"
  let dest = temp <> "/dest"

  // Create source with file
  let assert Ok(Nil) = simplifile.create_directory(src)
  let assert Ok(Nil) = simplifile.write(src <> "/test.txt", "hello")

  // Copy
  let assert Ok(Nil) = e2e_helpers.copy_directory(src, dest)

  // Verify file was copied
  let assert Ok("hello") = simplifile.read(dest <> "/test.txt")

  // Cleanup
  let assert Ok(Nil) = e2e_helpers.cleanup_temp_dir(temp)
}

pub fn copy_directory_preserves_structure_test() {
  let assert Ok(temp) = e2e_helpers.create_temp_dir("nested_copy")
  let src = temp <> "/src"
  let dest = temp <> "/dest"

  // Create nested structure
  let assert Ok(Nil) = simplifile.create_directory_all(src <> "/sub/dir")
  let assert Ok(Nil) = simplifile.write(src <> "/root.txt", "root")
  let assert Ok(Nil) = simplifile.write(src <> "/sub/middle.txt", "middle")
  let assert Ok(Nil) = simplifile.write(src <> "/sub/dir/deep.txt", "deep")

  // Copy
  let assert Ok(Nil) = e2e_helpers.copy_directory(src, dest)

  // Verify structure
  let assert Ok("root") = simplifile.read(dest <> "/root.txt")
  let assert Ok("middle") = simplifile.read(dest <> "/sub/middle.txt")
  let assert Ok("deep") = simplifile.read(dest <> "/sub/dir/deep.txt")

  // Cleanup
  let assert Ok(Nil) = e2e_helpers.cleanup_temp_dir(temp)
}

// === Path Helper Tests ===

pub fn fixtures_dir_returns_correct_path_test() {
  e2e_helpers.fixtures_dir()
  |> should.equal("test/fixtures")
}

pub fn e2e_dir_returns_correct_path_test() {
  e2e_helpers.e2e_dir()
  |> should.equal("test/e2e")
}

pub fn project_template_dir_returns_correct_path_test() {
  e2e_helpers.project_template_dir()
  |> should.equal("test/e2e/project_template")
}

pub fn generated_dir_returns_correct_path_test() {
  e2e_helpers.generated_dir()
  |> should.equal("test/e2e/generated")
}

// === Shell Execution Tests ===

pub fn run_command_success_test() {
  // Run a simple echo command
  let result = e2e_helpers.run_command("echo", ["hello"], ".")

  result.exit_code
  |> should.equal(0)

  result.stdout
  |> string.trim
  |> should.equal("hello")
}

pub fn run_command_with_cwd_test() {
  // Run ls in the test directory
  let result = e2e_helpers.run_command("ls", [], "test")

  result.exit_code
  |> should.equal(0)

  // Should contain known files/directories
  result.stdout
  |> string.contains("e2e")
  |> should.be_true
}

pub fn run_command_failure_test() {
  // Run a command that should fail
  let result = e2e_helpers.run_command("ls", ["nonexistent_dir_xyz"], ".")

  // Exit code should be non-zero
  should.not_equal(result.exit_code, 0)
}

pub fn gleam_build_in_valid_project_test() {
  // Run gleam build in the project root (should succeed)
  let result = e2e_helpers.gleam_build(".")

  result.exit_code
  |> should.equal(0)
}

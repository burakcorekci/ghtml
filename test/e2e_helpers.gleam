//// E2E test helper utilities.
////
//// Provides utilities for E2E testing including:
//// - Temporary directory management
//// - Shell command execution
//// - Path helpers for test directories
////
//// ## Usage
////
//// ```gleam
//// import e2e_helpers
////
//// pub fn my_e2e_test() {
////   // Create a temp directory for the test
////   let assert Ok(temp_dir) = e2e_helpers.create_temp_dir("my_test")
////
////   // Copy project template
////   let assert Ok(Nil) = e2e_helpers.copy_directory(
////     e2e_helpers.project_template_dir(),
////     temp_dir,
////   )
////
////   // Run gleam build
////   let result = e2e_helpers.gleam_build(temp_dir)
////   should.equal(result.exit_code, 0)
////
////   // Cleanup
////   let assert Ok(Nil) = e2e_helpers.cleanup_temp_dir(temp_dir)
//// }
//// ```

import gleam/erlang/reference
import gleam/result
import gleam/string
import shellout
import simplifile

/// Base directory for test artifacts (gitignored)
const test_base = ".test"

// === Temp Directory Helpers ===

/// Creates a temporary directory for E2E testing.
///
/// Returns the path to the created directory.
/// Uses `.test/` directory (gitignored) for visibility during debugging.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(path) = create_temp_dir("build_test")
/// // path might be ".test/e2e_build_test_1234567890"
/// ```
pub fn create_temp_dir(prefix: String) -> Result(String, simplifile.FileError) {
  let unique_id = get_unique_id()
  let path = test_base <> "/e2e_" <> prefix <> "_" <> unique_id

  use _ <- result.try(simplifile.create_directory_all(path))
  Ok(path)
}

/// Removes a temporary directory and all its contents.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(Nil) = cleanup_temp_dir(".test/e2e_test_123")
/// ```
pub fn cleanup_temp_dir(path: String) -> Result(Nil, simplifile.FileError) {
  simplifile.delete(path)
}

/// Copies a directory recursively.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(Nil) = copy_directory("test/e2e/project_template", ".test/e2e_test_123")
/// ```
pub fn copy_directory(
  src: String,
  dest: String,
) -> Result(Nil, simplifile.FileError) {
  simplifile.copy_directory(src, dest)
}

/// Gets a unique string for directory naming.
/// Uses Erlang's reference mechanism to ensure uniqueness.
fn get_unique_id() -> String {
  reference.new()
  |> string.inspect
  |> string.replace("#Reference<", "")
  |> string.replace(">", "")
  |> string.replace(".", "_")
}

// === Shell Execution Helpers ===

/// Result of a shell command execution.
pub type CommandResult {
  CommandResult(exit_code: Int, stdout: String, stderr: String)
}

/// Executes a shell command in the given directory.
///
/// Returns a CommandResult with exit code, stdout, and stderr.
/// Note: When using shellout, stderr is merged into stdout on success,
/// and stderr contains the error message on failure.
///
/// ## Examples
///
/// ```gleam
/// let result = run_command("echo", ["hello"], ".")
/// // result.exit_code == 0
/// // result.stdout == "hello\n"
/// ```
pub fn run_command(
  command: String,
  args: List(String),
  cwd: String,
) -> CommandResult {
  case shellout.command(run: command, with: args, in: cwd, opt: []) {
    Ok(output) -> CommandResult(exit_code: 0, stdout: output, stderr: "")
    Error(#(exit_code, error_output)) ->
      CommandResult(exit_code: exit_code, stdout: "", stderr: error_output)
  }
}

/// Runs `gleam build` in the specified directory.
///
/// ## Examples
///
/// ```gleam
/// let result = gleam_build(".")
/// should.equal(result.exit_code, 0)
/// ```
pub fn gleam_build(project_dir: String) -> CommandResult {
  run_command("gleam", ["build"], project_dir)
}

// === Path Helpers ===

/// Returns the path to the shared fixtures directory.
///
/// This directory contains fixtures used by unit, integration, and e2e tests.
pub fn fixtures_dir() -> String {
  "test/fixtures"
}

/// Returns the path to the E2E test directory.
pub fn e2e_dir() -> String {
  "test/e2e"
}

/// Returns the path to the project template fixture.
///
/// This is a minimal Gleam project structure used as a base for E2E tests.
pub fn project_template_dir() -> String {
  e2e_dir() <> "/lustre/project_template"
}

/// Returns the path to the generated SSR test modules directory.
///
/// This directory contains pre-generated modules for SSR testing.
pub fn generated_dir() -> String {
  e2e_dir() <> "/lustre/generated"
}

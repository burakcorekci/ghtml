import ghtml/scanner
import ghtml/watcher
import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/option.{None}
import gleam/string
import gleeunit/should
import simplifile

// Helper to create test directory structure
fn setup_test_dir(base: String) -> Nil {
  let _ = simplifile.create_directory_all(base <> "/src")
  Nil
}

fn cleanup_test_dir(base: String) {
  let _ = simplifile.delete(base)
  Nil
}

// Note: Testing OTP actors requires careful timing.
// These tests verify the components work correctly.

pub fn get_mtime_test() {
  let test_dir = ".test/watcher_mtime_1"
  setup_test_dir(test_dir)

  let path = test_dir <> "/src/test.ghtml"
  let _ = simplifile.write(path, "<div></div>")

  // Should get a valid mtime
  let result = watcher.get_mtime(path)
  should.be_ok(result)

  // mtime should be a reasonable value (> 0)
  let assert Ok(mtime) = result
  should.be_true(mtime > 0)

  cleanup_test_dir(test_dir)
}

pub fn get_mtime_nonexistent_test() {
  // Should return Error for nonexistent file
  let result = watcher.get_mtime(".test/nonexistent_file_xyz.ghtml")
  should.be_error(result)
}

pub fn get_all_mtimes_test() {
  let test_dir = ".test/watcher_mtimes_1"
  setup_test_dir(test_dir)

  // Create files
  let _ = simplifile.write(test_dir <> "/src/a.ghtml", "<div></div>")
  let _ = simplifile.write(test_dir <> "/src/b.ghtml", "<span></span>")

  // Get mtimes
  let mtimes = watcher.get_all_mtimes(test_dir)

  // Should have 2 entries
  should.equal(dict.size(mtimes), 2)

  cleanup_test_dir(test_dir)
}

pub fn get_all_mtimes_empty_dir_test() {
  let test_dir = ".test/watcher_mtimes_2"
  setup_test_dir(test_dir)

  // No .ghtml files
  let mtimes = watcher.get_all_mtimes(test_dir)

  // Should be empty
  should.equal(dict.size(mtimes), 0)

  cleanup_test_dir(test_dir)
}

pub fn detect_new_file_test() {
  let test_dir = ".test/watcher_detect_1"
  setup_test_dir(test_dir)

  // Initial state with no files
  let state =
    watcher.WatcherState(
      root: test_dir,
      file_mtimes: dict.new(),
      self_subject: None,
    )

  // Create a new file
  let _ = simplifile.write(test_dir <> "/src/new.ghtml", "<div></div>")

  // Check for changes would detect new file
  let current_files = scanner.find_ghtml_files(test_dir)
  should.equal(list.length(current_files), 1)

  // The file would not be in old mtimes
  should.equal(
    dict.get(state.file_mtimes, test_dir <> "/src/new.ghtml"),
    Error(Nil),
  )

  cleanup_test_dir(test_dir)
}

pub fn detect_modified_file_test() {
  let test_dir = ".test/watcher_detect_2"
  setup_test_dir(test_dir)

  // Create initial file
  let path = test_dir <> "/src/test.ghtml"
  let _ = simplifile.write(path, "<div></div>")

  // Get initial mtime
  let assert Ok(initial_mtime) = watcher.get_mtime(path)

  // Wait a bit and modify - mtime resolution is 1 second on many systems
  process.sleep(1100)
  let _ = simplifile.write(path, "<div>modified</div>")

  // Get new mtime
  let assert Ok(new_mtime) = watcher.get_mtime(path)

  // Mtimes should differ
  should.not_equal(initial_mtime, new_mtime)

  cleanup_test_dir(test_dir)
}

pub fn detect_deleted_file_test() {
  let test_dir = ".test/watcher_detect_3"
  setup_test_dir(test_dir)

  // Create file
  let path = test_dir <> "/src/temp.ghtml"
  let _ = simplifile.write(path, "<div></div>")

  // Get initial state
  let initial_files = scanner.find_ghtml_files(test_dir)
  should.equal(list.length(initial_files), 1)

  // Delete file
  let _ = simplifile.delete(path)

  // Current files should be empty
  let current_files = scanner.find_ghtml_files(test_dir)
  should.equal(list.length(current_files), 0)

  cleanup_test_dir(test_dir)
}

pub fn process_single_file_test() {
  let test_dir = ".test/watcher_process_1"
  setup_test_dir(test_dir)

  // Create source file
  let source = test_dir <> "/src/component.ghtml"
  let output = test_dir <> "/src/component.gleam"
  let _ = simplifile.write(source, "@params(name: String)\n\n<div>{name}</div>")

  // Process file
  watcher.process_single_file(source)

  // Check output was created
  let assert Ok(True) = simplifile.is_file(output)

  // Check content
  let assert Ok(content) = simplifile.read(output)
  should.be_true(string.contains(content, "pub fn render("))

  cleanup_test_dir(test_dir)
}

pub fn process_single_file_parse_error_test() {
  let test_dir = ".test/watcher_process_2"
  setup_test_dir(test_dir)

  // Create source file with invalid content
  let source = test_dir <> "/src/invalid.ghtml"
  let output = test_dir <> "/src/invalid.gleam"
  let _ = simplifile.write(source, "<div><unclosed>")

  // Process file - should not crash, just report error
  watcher.process_single_file(source)

  // Output should NOT be created due to parse error
  let result = simplifile.is_file(output)
  should.equal(result, Ok(False))

  cleanup_test_dir(test_dir)
}

pub fn watcher_state_update_test() {
  let test_dir = ".test/watcher_state_1"
  setup_test_dir(test_dir)

  // Create initial file
  let _ = simplifile.write(test_dir <> "/src/a.ghtml", "<div></div>")

  // Initial state
  let initial_mtimes = watcher.get_all_mtimes(test_dir)
  should.equal(dict.size(initial_mtimes), 1)

  // Add another file
  let _ = simplifile.write(test_dir <> "/src/b.ghtml", "<span></span>")

  // Updated mtimes should have 2 entries
  let updated_mtimes = watcher.get_all_mtimes(test_dir)
  should.equal(dict.size(updated_mtimes), 2)

  cleanup_test_dir(test_dir)
}

// Integration test for watch mode
// This test starts the watcher briefly to verify it doesn't crash

pub fn watcher_starts_without_error_test() {
  let test_dir = ".test/watcher_start_1"
  setup_test_dir(test_dir)

  // Create a file
  let _ = simplifile.write(test_dir <> "/src/test.ghtml", "<div></div>")

  // Start watcher
  let subject = watcher.start_watching(test_dir)

  // Let it run briefly
  process.sleep(100)

  // Stop it
  process.send(subject, watcher.Stop)

  // Give it time to stop
  process.sleep(100)

  cleanup_test_dir(test_dir)
}

pub fn watcher_detects_new_file_test() {
  let test_dir = ".test/watcher_gen_1"
  setup_test_dir(test_dir)

  // Start watcher with empty directory
  let subject = watcher.start_watching(test_dir)

  // Wait for first check
  process.sleep(100)

  // Create a NEW file after watcher started
  let source = test_dir <> "/src/test.ghtml"
  let output = test_dir <> "/src/test.gleam"
  let _ = simplifile.write(source, "<div>initial</div>")

  // Wait for next check to detect the new file
  process.sleep(600)

  // Output should be generated
  let assert Ok(True) = simplifile.is_file(output)

  // Stop watcher
  process.send(subject, watcher.Stop)
  process.sleep(100)

  cleanup_test_dir(test_dir)
}

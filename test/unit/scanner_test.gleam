import ghtml/scanner
import gleam/list
import gleam/string
import gleeunit/should
import simplifile

// Helper to create test directory structure
fn setup_test_dir(base: String) {
  let _ = simplifile.create_directory_all(base <> "/src/components")
  let _ = simplifile.create_directory_all(base <> "/src/pages")
  let _ = simplifile.create_directory_all(base <> "/build")
  let _ = simplifile.create_directory_all(base <> "/.git")
  let _ = simplifile.create_directory_all(base <> "/node_modules/pkg")

  // Create .ghtml files
  let _ = simplifile.write(base <> "/src/app.ghtml", "")
  let _ = simplifile.write(base <> "/src/components/button.ghtml", "")
  let _ = simplifile.write(base <> "/src/components/card.ghtml", "")
  let _ = simplifile.write(base <> "/src/pages/home.ghtml", "")

  // Create files in ignored directories (should not be found)
  let _ = simplifile.write(base <> "/build/cached.ghtml", "")
  let _ = simplifile.write(base <> "/.git/hooks.ghtml", "")
  let _ = simplifile.write(base <> "/node_modules/pkg/template.ghtml", "")

  // Create .gleam files
  let _ = simplifile.write(base <> "/src/main.gleam", "")
  let _ = simplifile.write(base <> "/src/components/button.gleam", "")
  Nil
}

fn cleanup_test_dir(base: String) {
  let _ = simplifile.delete(base)
  Nil
}

pub fn find_ghtml_files_test() {
  let test_dir = ".test/scanner_test_1"
  let _ = setup_test_dir(test_dir)

  let files = scanner.find_ghtml_files(test_dir)

  // Should find exactly 4 .ghtml files
  should.equal(list.length(files), 4)

  // Should contain expected files
  should.be_true(list.any(files, fn(f) { string.contains(f, "app.ghtml") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "button.ghtml") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "card.ghtml") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "home.ghtml") }))

  // Should NOT contain ignored directory files
  should.be_false(list.any(files, fn(f) { string.contains(f, "build/") }))
  should.be_false(list.any(files, fn(f) { string.contains(f, ".git/") }))
  should.be_false(
    list.any(files, fn(f) { string.contains(f, "node_modules/") }),
  )

  cleanup_test_dir(test_dir)
}

pub fn find_ghtml_files_empty_dir_test() {
  let test_dir = ".test/scanner_test_2"
  let _ = simplifile.create_directory_all(test_dir)

  let files = scanner.find_ghtml_files(test_dir)
  should.equal(files, [])

  cleanup_test_dir(test_dir)
}

pub fn find_ghtml_files_nonexistent_dir_test() {
  let files = scanner.find_ghtml_files(".test/nonexistent_dir_xyz")
  should.equal(files, [])
}

pub fn to_output_path_test() {
  should.equal(scanner.to_output_path("src/app.ghtml"), "src/app.gleam")
  should.equal(
    scanner.to_output_path("src/components/button.ghtml"),
    "src/components/button.gleam",
  )
  should.equal(scanner.to_output_path("./test.ghtml"), "./test.gleam")
}

pub fn to_source_path_test() {
  should.equal(scanner.to_source_path("src/app.gleam"), "src/app.ghtml")
  should.equal(
    scanner.to_source_path("src/components/button.gleam"),
    "src/components/button.ghtml",
  )
}

pub fn find_generated_files_test() {
  let test_dir = ".test/scanner_test_3"
  let _ = setup_test_dir(test_dir)

  let files = scanner.find_generated_files(test_dir)

  // Should find .gleam files
  should.be_true(list.any(files, fn(f) { string.contains(f, "main.gleam") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "button.gleam") }))

  // Should NOT find .ghtml files
  should.be_false(list.any(files, fn(f) { string.contains(f, ".ghtml") }))

  cleanup_test_dir(test_dir)
}

pub fn path_conversion_roundtrip_test() {
  let original = "src/components/my_component.ghtml"
  let gleam_path = scanner.to_output_path(original)
  let back = scanner.to_source_path(gleam_path)
  should.equal(back, original)
}

// Helper to create a generated file with proper header
fn create_generated_file(path: String, source_name: String) {
  let content =
    "// @generated from "
    <> source_name
    <> "\n// @hash abc123\n// DO NOT EDIT\n\nimport lustre/element.{type Element}\n\npub fn render() -> Element(msg) {\n  element.none()\n}\n"
  let _ = simplifile.write(path, content)
  Nil
}

// Helper to create a hand-written file
fn create_handwritten_file(path: String) {
  let content =
    "// This is a hand-written file\n\npub fn main() {\n  io.println(\"Hello\")\n}\n"
  let _ = simplifile.write(path, content)
  Nil
}

pub fn cleanup_removes_orphan_test() {
  let test_dir = ".test/orphan_test_1"
  let _ = simplifile.create_directory_all(test_dir <> "/src")

  // Create a generated file WITHOUT a source
  create_generated_file(test_dir <> "/src/orphan.gleam", "orphan.ghtml")

  // Verify file exists
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/orphan.gleam")

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should have removed 1 file
  should.equal(removed, 1)

  // File should no longer exist
  let assert Ok(False) = simplifile.is_file(test_dir <> "/src/orphan.gleam")

  cleanup_test_dir(test_dir)
}

pub fn cleanup_keeps_file_with_source_test() {
  let test_dir = ".test/orphan_test_2"
  let _ = simplifile.create_directory_all(test_dir <> "/src")

  // Create source file
  let _ = simplifile.write(test_dir <> "/src/component.ghtml", "<div></div>")

  // Create generated file WITH a source
  create_generated_file(test_dir <> "/src/component.gleam", "component.ghtml")

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should not have removed anything
  should.equal(removed, 0)

  // File should still exist
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/component.gleam")

  cleanup_test_dir(test_dir)
}

pub fn cleanup_keeps_handwritten_files_test() {
  let test_dir = ".test/orphan_test_3"
  let _ = simplifile.create_directory_all(test_dir <> "/src")

  // Create a hand-written file (no source needed, should never be deleted)
  create_handwritten_file(test_dir <> "/src/utils.gleam")

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should not have removed anything
  should.equal(removed, 0)

  // File should still exist
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/utils.gleam")

  cleanup_test_dir(test_dir)
}

pub fn cleanup_nested_directories_test() {
  let test_dir = ".test/orphan_test_4"
  let _ = simplifile.create_directory_all(test_dir <> "/src/components/nested")

  // Create orphan in nested directory
  create_generated_file(
    test_dir <> "/src/components/nested/orphan.gleam",
    "orphan.ghtml",
  )

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should have removed the orphan
  should.equal(removed, 1)

  cleanup_test_dir(test_dir)
}

pub fn cleanup_multiple_orphans_test() {
  let test_dir = ".test/orphan_test_5"
  let _ = simplifile.create_directory_all(test_dir <> "/src/components")

  // Create multiple orphans
  create_generated_file(test_dir <> "/src/orphan1.gleam", "orphan1.ghtml")
  create_generated_file(test_dir <> "/src/orphan2.gleam", "orphan2.ghtml")
  create_generated_file(
    test_dir <> "/src/components/orphan3.gleam",
    "orphan3.ghtml",
  )

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should have removed all 3
  should.equal(removed, 3)

  cleanup_test_dir(test_dir)
}

pub fn cleanup_mixed_files_test() {
  let test_dir = ".test/orphan_test_6"
  let _ = simplifile.create_directory_all(test_dir <> "/src")

  // Create source with generated output (should keep)
  let _ = simplifile.write(test_dir <> "/src/valid.ghtml", "<div></div>")
  create_generated_file(test_dir <> "/src/valid.gleam", "valid.ghtml")

  // Create orphan (should remove)
  create_generated_file(test_dir <> "/src/orphan.gleam", "orphan.ghtml")

  // Create hand-written file (should keep)
  create_handwritten_file(test_dir <> "/src/utils.gleam")

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should have removed only the orphan
  should.equal(removed, 1)

  // Verify file states
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/valid.gleam")
  let assert Ok(False) = simplifile.is_file(test_dir <> "/src/orphan.gleam")
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/utils.gleam")

  cleanup_test_dir(test_dir)
}

pub fn cleanup_empty_directory_test() {
  let test_dir = ".test/orphan_test_7"
  let _ = simplifile.create_directory_all(test_dir <> "/src")

  // Run cleanup on empty directory
  let removed = scanner.cleanup_orphans(test_dir)

  // Should return 0
  should.equal(removed, 0)

  cleanup_test_dir(test_dir)
}

pub fn find_orphans_test() {
  let test_dir = ".test/orphan_test_8"
  let _ = simplifile.create_directory_all(test_dir <> "/src")

  // Create orphan
  create_generated_file(test_dir <> "/src/orphan.gleam", "orphan.ghtml")

  // Create valid pair
  let _ = simplifile.write(test_dir <> "/src/valid.ghtml", "<div></div>")
  create_generated_file(test_dir <> "/src/valid.gleam", "valid.ghtml")

  // Find orphans (without deleting)
  let orphans = scanner.find_orphans(test_dir)

  // Should find 1 orphan
  should.equal(list.length(orphans), 1)
  should.be_true(
    list.any(orphans, fn(p) { string.contains(p, "orphan.gleam") }),
  )

  // Files should still exist
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/orphan.gleam")

  cleanup_test_dir(test_dir)
}

pub fn is_generated_detection_test() {
  // Test the is_generated function indirectly through cleanup behavior
  let test_dir = ".test/orphan_test_9"
  let _ = simplifile.create_directory_all(test_dir <> "/src")

  // File starting with @generated marker
  let _ =
    simplifile.write(
      test_dir <> "/src/gen1.gleam",
      "// @generated from test.ghtml\n\npub fn render() {}\n",
    )

  // File with @generated but not at start
  let _ =
    simplifile.write(
      test_dir <> "/src/gen2.gleam",
      "// Some comment\n// @generated from test.ghtml\n\npub fn render() {}\n",
    )

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Only gen1 should be removed (marker at start)
  should.equal(removed, 1)

  // gen2 should still exist (marker not at start, so not detected as generated)
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/gen2.gleam")

  cleanup_test_dir(test_dir)
}

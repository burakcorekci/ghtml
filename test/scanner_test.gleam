import gleam/list
import gleam/string
import gleeunit/should
import lustre_template_gen/scanner
import simplifile

// Helper to create test directory structure
fn setup_test_dir(base: String) {
  let _ = simplifile.create_directory_all(base <> "/src/components")
  let _ = simplifile.create_directory_all(base <> "/src/pages")
  let _ = simplifile.create_directory_all(base <> "/build")
  let _ = simplifile.create_directory_all(base <> "/.git")
  let _ = simplifile.create_directory_all(base <> "/node_modules/pkg")

  // Create .lustre files
  let _ = simplifile.write(base <> "/src/app.lustre", "")
  let _ = simplifile.write(base <> "/src/components/button.lustre", "")
  let _ = simplifile.write(base <> "/src/components/card.lustre", "")
  let _ = simplifile.write(base <> "/src/pages/home.lustre", "")

  // Create files in ignored directories (should not be found)
  let _ = simplifile.write(base <> "/build/cached.lustre", "")
  let _ = simplifile.write(base <> "/.git/hooks.lustre", "")
  let _ = simplifile.write(base <> "/node_modules/pkg/template.lustre", "")

  // Create .gleam files
  let _ = simplifile.write(base <> "/src/main.gleam", "")
  let _ = simplifile.write(base <> "/src/components/button.gleam", "")
  Nil
}

fn cleanup_test_dir(base: String) {
  let _ = simplifile.delete(base)
  Nil
}

pub fn find_lustre_files_test() {
  let test_dir = ".test/scanner_test_1"
  let _ = setup_test_dir(test_dir)

  let files = scanner.find_lustre_files(test_dir)

  // Should find exactly 4 .lustre files
  should.equal(list.length(files), 4)

  // Should contain expected files
  should.be_true(list.any(files, fn(f) { string.contains(f, "app.lustre") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "button.lustre") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "card.lustre") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "home.lustre") }))

  // Should NOT contain ignored directory files
  should.be_false(list.any(files, fn(f) { string.contains(f, "build/") }))
  should.be_false(list.any(files, fn(f) { string.contains(f, ".git/") }))
  should.be_false(
    list.any(files, fn(f) { string.contains(f, "node_modules/") }),
  )

  cleanup_test_dir(test_dir)
}

pub fn find_lustre_files_empty_dir_test() {
  let test_dir = ".test/scanner_test_2"
  let _ = simplifile.create_directory_all(test_dir)

  let files = scanner.find_lustre_files(test_dir)
  should.equal(files, [])

  cleanup_test_dir(test_dir)
}

pub fn find_lustre_files_nonexistent_dir_test() {
  let files = scanner.find_lustre_files(".test/nonexistent_dir_xyz")
  should.equal(files, [])
}

pub fn to_output_path_test() {
  should.equal(scanner.to_output_path("src/app.lustre"), "src/app.gleam")
  should.equal(
    scanner.to_output_path("src/components/button.lustre"),
    "src/components/button.gleam",
  )
  should.equal(scanner.to_output_path("./test.lustre"), "./test.gleam")
}

pub fn to_source_path_test() {
  should.equal(scanner.to_source_path("src/app.gleam"), "src/app.lustre")
  should.equal(
    scanner.to_source_path("src/components/button.gleam"),
    "src/components/button.lustre",
  )
}

pub fn find_generated_files_test() {
  let test_dir = ".test/scanner_test_3"
  let _ = setup_test_dir(test_dir)

  let files = scanner.find_generated_files(test_dir)

  // Should find .gleam files
  should.be_true(list.any(files, fn(f) { string.contains(f, "main.gleam") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "button.gleam") }))

  // Should NOT find .lustre files
  should.be_false(list.any(files, fn(f) { string.contains(f, ".lustre") }))

  cleanup_test_dir(test_dir)
}

pub fn path_conversion_roundtrip_test() {
  let original = "src/components/my_component.lustre"
  let gleam_path = scanner.to_output_path(original)
  let back = scanner.to_source_path(gleam_path)
  should.equal(back, original)
}

//// CLI integration tests.
////
//// Tests for the main CLI entry point that ties together all modules:
//// scanning, caching, parsing, code generation, and file writing.

import ghtml
import ghtml/cache
import ghtml/codegen
import ghtml/parser
import ghtml/scanner
import gleam/list
import gleam/string
import gleeunit/should
import simplifile

fn setup_test_project(base: String) -> Nil {
  let _ = simplifile.create_directory_all(base <> "/src/components")

  // Create a simple .ghtml file
  let lustre_content =
    "@params(name: String)

<div class=\"greeting\">
  Hello, {name}!
</div>"

  let _ =
    simplifile.write(base <> "/src/components/greeting.ghtml", lustre_content)
  Nil
}

fn cleanup_test_project(base: String) {
  let _ = simplifile.delete(base)
  Nil
}

// === Option Parsing Tests ===

pub fn parse_options_default_test() {
  let options = ghtml.parse_options([])
  should.be_false(options.force)
  should.be_false(options.clean_only)
  should.be_false(options.watch)
  should.equal(options.root, ".")
}

pub fn parse_options_force_test() {
  let options = ghtml.parse_options(["force"])
  should.be_true(options.force)
  should.be_false(options.clean_only)
  should.equal(options.root, ".")
}

pub fn parse_options_clean_test() {
  let options = ghtml.parse_options(["clean"])
  should.be_true(options.clean_only)
  should.be_false(options.force)
}

pub fn parse_options_watch_test() {
  let options = ghtml.parse_options(["watch"])
  should.be_true(options.watch)
}

pub fn parse_options_multiple_test() {
  let options = ghtml.parse_options(["force", "watch"])
  should.be_true(options.force)
  should.be_true(options.watch)
  should.be_false(options.clean_only)
  should.equal(options.root, ".")
}

pub fn parse_options_with_root_test() {
  let options = ghtml.parse_options(["./my-project"])
  should.be_false(options.force)
  should.equal(options.root, "./my-project")
}

pub fn parse_options_with_root_and_flags_test() {
  let options = ghtml.parse_options(["force", "./my-project"])
  should.be_true(options.force)
  should.equal(options.root, "./my-project")
}

// === File Processing Tests ===

pub fn process_simple_file_test() {
  let test_dir = ".test/cli_test_1"
  setup_test_project(test_dir)

  let source = test_dir <> "/src/components/greeting.ghtml"
  let output = test_dir <> "/src/components/greeting.gleam"

  // Read and process
  let assert Ok(content) = simplifile.read(source)
  let hash = cache.hash_content(content)

  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, source, hash)

  let _ = simplifile.write(output, code)

  // Verify output exists
  let assert Ok(True) = simplifile.is_file(output)

  // Verify output content
  let assert Ok(generated) = simplifile.read(output)
  should.be_true(string.contains(generated, "// @generated from"))
  should.be_true(string.contains(generated, "// @hash"))
  should.be_true(string.contains(generated, "pub fn render("))
  should.be_true(string.contains(generated, "name: String"))
  should.be_true(string.contains(generated, "html.div("))
  should.be_true(string.contains(generated, "text(name)"))

  cleanup_test_project(test_dir)
}

pub fn cache_skip_unchanged_test() {
  let test_dir = ".test/cli_test_2"
  setup_test_project(test_dir)

  let source = test_dir <> "/src/components/greeting.ghtml"
  let output = test_dir <> "/src/components/greeting.gleam"

  // First generation
  let assert Ok(content) = simplifile.read(source)
  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, source, hash)
  let _ = simplifile.write(output, code)

  // Check if regeneration is needed
  should.be_false(cache.needs_regeneration(source, output))

  cleanup_test_project(test_dir)
}

pub fn cache_detect_change_test() {
  let test_dir = ".test/cli_test_3"
  setup_test_project(test_dir)

  let source = test_dir <> "/src/components/greeting.ghtml"
  let output = test_dir <> "/src/components/greeting.gleam"

  // First generation
  let assert Ok(content) = simplifile.read(source)
  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, source, hash)
  let _ = simplifile.write(output, code)

  // Modify source
  let new_content =
    "@params(name: String, age: Int)

<div class=\"greeting\">
  Hello, {name}! You are {int.to_string(age)} years old.
</div>"
  let _ = simplifile.write(source, new_content)

  // Check if regeneration is needed
  should.be_true(cache.needs_regeneration(source, output))

  cleanup_test_project(test_dir)
}

pub fn scanner_finds_files_test() {
  let test_dir = ".test/cli_test_4"
  setup_test_project(test_dir)

  let files = scanner.find_ghtml_files(test_dir)

  should.equal(list.length(files), 1)
  should.be_true(
    list.any(files, fn(f) { string.contains(f, "greeting.ghtml") }),
  )

  cleanup_test_project(test_dir)
}

pub fn output_path_conversion_test() {
  let source = "src/components/card.ghtml"
  let output = scanner.to_output_path(source)

  should.equal(output, "src/components/card.gleam")
}

// === Orphan Cleanup Tests ===

pub fn cleanup_orphans_removes_orphaned_files_test() {
  let test_dir = ".test/cli_test_orphan"
  let _ = simplifile.create_directory_all(test_dir <> "/src")

  // Create a generated file without a source
  let orphan_content =
    "// @generated from orphan.ghtml
// @hash abc123
// DO NOT EDIT
pub fn render() { todo }"
  let _ = simplifile.write(test_dir <> "/src/orphan.gleam", orphan_content)

  // Run cleanup
  let count = scanner.cleanup_orphans(test_dir)

  should.equal(count, 1)

  // Verify file was deleted
  let assert Ok(False) = simplifile.is_file(test_dir <> "/src/orphan.gleam")

  cleanup_test_project(test_dir)
}

pub fn cleanup_orphans_keeps_non_generated_files_test() {
  let test_dir = ".test/cli_test_orphan2"
  let _ = simplifile.create_directory_all(test_dir <> "/src")

  // Create a regular gleam file (not generated)
  let regular_content = "pub fn main() { todo }"
  let _ = simplifile.write(test_dir <> "/src/app.gleam", regular_content)

  // Run cleanup
  let count = scanner.cleanup_orphans(test_dir)

  should.equal(count, 0)

  // Verify file still exists
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/app.gleam")

  cleanup_test_project(test_dir)
}

pub fn cleanup_orphans_keeps_files_with_source_test() {
  let test_dir = ".test/cli_test_orphan3"
  setup_test_project(test_dir)

  let source = test_dir <> "/src/components/greeting.ghtml"
  let output = test_dir <> "/src/components/greeting.gleam"

  // Generate the file
  let assert Ok(content) = simplifile.read(source)
  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, source, hash)
  let _ = simplifile.write(output, code)

  // Run cleanup
  let count = scanner.cleanup_orphans(test_dir)

  should.equal(count, 0)

  // Verify file still exists
  let assert Ok(True) = simplifile.is_file(output)

  cleanup_test_project(test_dir)
}

// === Generation Stats Tests ===

pub fn generate_all_returns_stats_test() {
  let test_dir = ".test/cli_test_stats"
  setup_test_project(test_dir)

  // Run generate_all
  let stats = ghtml.generate_all(test_dir, False)

  should.equal(stats.generated, 1)
  should.equal(stats.skipped, 0)
  should.equal(stats.errors, 0)

  cleanup_test_project(test_dir)
}

pub fn generate_all_skips_unchanged_test() {
  let test_dir = ".test/cli_test_stats2"
  setup_test_project(test_dir)

  // First generation
  let _ = ghtml.generate_all(test_dir, False)

  // Second generation should skip
  let stats = ghtml.generate_all(test_dir, False)

  should.equal(stats.generated, 0)
  should.equal(stats.skipped, 1)
  should.equal(stats.errors, 0)

  cleanup_test_project(test_dir)
}

pub fn generate_all_force_regenerates_test() {
  let test_dir = ".test/cli_test_stats3"
  setup_test_project(test_dir)

  // First generation
  let _ = ghtml.generate_all(test_dir, False)

  // Force regeneration
  let stats = ghtml.generate_all(test_dir, True)

  should.equal(stats.generated, 1)
  should.equal(stats.skipped, 0)

  cleanup_test_project(test_dir)
}

// === Generated Code Validity Test ===

pub fn generated_code_has_correct_structure_test() {
  let test_dir = ".test/cli_test_5"
  let _ = simplifile.create_directory_all(test_dir <> "/src")

  // Create a simple .ghtml file
  let lustre_content =
    "@params(message: String)

<div class=\"box\">
  <p>{message}</p>
</div>"
  let _ = simplifile.write(test_dir <> "/src/template.ghtml", lustre_content)

  // Generate the .gleam file
  let assert Ok(content) = simplifile.read(test_dir <> "/src/template.ghtml")
  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, "template.ghtml", hash)
  let _ = simplifile.write(test_dir <> "/src/template.gleam", code)

  // Verify the code looks correct
  let assert Ok(generated) = simplifile.read(test_dir <> "/src/template.gleam")
  should.be_true(string.contains(generated, "import lustre/element"))
  should.be_true(string.contains(generated, "pub fn render("))
  should.be_true(string.contains(generated, "html.div("))
  should.be_true(string.contains(generated, "html.p("))

  cleanup_test_project(test_dir)
}

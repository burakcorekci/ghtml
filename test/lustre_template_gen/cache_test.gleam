import gleam/list
import gleam/string
import gleeunit/should
import lustre_template_gen/cache
import simplifile

pub fn hash_content_consistency_test() {
  let content = "Hello, World!"
  let hash1 = cache.hash_content(content)
  let hash2 = cache.hash_content(content)

  // Same content should produce same hash
  should.equal(hash1, hash2)
}

pub fn hash_content_different_test() {
  let hash1 = cache.hash_content("Hello")
  let hash2 = cache.hash_content("World")

  // Different content should produce different hashes
  should.not_equal(hash1, hash2)
}

pub fn hash_content_format_test() {
  let hash = cache.hash_content("test")

  // Hash should be 64 characters (256 bits = 64 hex chars)
  should.equal(string.length(hash), 64)

  // Hash should be lowercase
  should.equal(hash, string.lowercase(hash))

  // Hash should only contain hex characters
  let is_hex =
    string.to_graphemes(hash)
    |> list.all(fn(c) { string.contains("0123456789abcdef", c) })
  should.be_true(is_hex)
}

pub fn hash_content_known_value_test() {
  // Known SHA-256 hash for "test"
  let hash = cache.hash_content("test")
  should.equal(
    hash,
    "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
  )
}

pub fn hash_content_empty_string_test() {
  let hash = cache.hash_content("")
  // Known SHA-256 hash for empty string
  should.equal(
    hash,
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  )
}

pub fn extract_hash_valid_test() {
  let content =
    "// @generated from test.lustre
// @hash abc123def456
// DO NOT EDIT

pub fn render() { }
"
  let result = cache.extract_hash(content)
  should.equal(result, Ok("abc123def456"))
}

pub fn extract_hash_with_extra_whitespace_test() {
  let content =
    "// @generated from test.lustre
// @hash   abc123def456
// DO NOT EDIT
"
  let result = cache.extract_hash(content)
  should.equal(result, Ok("abc123def456"))
}

pub fn extract_hash_missing_test() {
  let content =
    "// Some other file
pub fn render() { }
"
  let result = cache.extract_hash(content)
  should.equal(result, Error(Nil))
}

pub fn extract_hash_no_hash_line_test() {
  let content =
    "// @generated from test.lustre
// DO NOT EDIT
pub fn render() { }
"
  let result = cache.extract_hash(content)
  should.equal(result, Error(Nil))
}

pub fn generate_header_test() {
  let header = cache.generate_header("test.lustre", "abc123")

  should.be_true(string.contains(header, "// @generated from test.lustre"))
  should.be_true(string.contains(header, "// @hash abc123"))
  should.be_true(string.contains(header, "DO NOT EDIT"))
}

pub fn is_generated_true_test() {
  let content =
    "// @generated from test.lustre
// @hash abc123
pub fn render() { }
"
  should.be_true(cache.is_generated(content))
}

pub fn is_generated_false_test() {
  let content =
    "// This is a regular file
pub fn main() { }
"
  should.be_false(cache.is_generated(content))
}

pub fn needs_regeneration_no_output_test() {
  let test_dir = ".test/cache_test_1"
  let _ = simplifile.create_directory_all(test_dir)
  let source = test_dir <> "/test.lustre"
  let output = test_dir <> "/test.gleam"

  let _ = simplifile.write(source, "<div>Hello</div>")
  // Don't create output file

  let result = cache.needs_regeneration(source, output)
  should.be_true(result)

  let _ = simplifile.delete(test_dir)
}

pub fn needs_regeneration_matching_hash_test() {
  let test_dir = ".test/cache_test_2"
  let _ = simplifile.create_directory_all(test_dir)
  let source = test_dir <> "/test.lustre"
  let output = test_dir <> "/test.gleam"

  let source_content = "<div>Hello</div>"
  let hash = cache.hash_content(source_content)
  let _ = simplifile.write(source, source_content)
  let _ =
    simplifile.write(
      output,
      "// @generated from test.lustre\n// @hash " <> hash <> "\n",
    )

  let result = cache.needs_regeneration(source, output)
  should.be_false(result)
  // Hashes match, no regeneration needed

  let _ = simplifile.delete(test_dir)
}

pub fn needs_regeneration_different_hash_test() {
  let test_dir = ".test/cache_test_3"
  let _ = simplifile.create_directory_all(test_dir)
  let source = test_dir <> "/test.lustre"
  let output = test_dir <> "/test.gleam"

  let _ = simplifile.write(source, "<div>Hello</div>")
  let _ =
    simplifile.write(
      output,
      "// @generated from test.lustre\n// @hash oldhash123\n",
    )

  let result = cache.needs_regeneration(source, output)
  should.be_true(result)
  // Hashes differ, regeneration needed

  let _ = simplifile.delete(test_dir)
}

pub fn needs_regeneration_no_source_test() {
  let result =
    cache.needs_regeneration(
      ".test/nonexistent.lustre",
      ".test/nonexistent.gleam",
    )
  should.be_false(result)
  // No source, don't try to regenerate
}

pub fn needs_regeneration_invalid_output_header_test() {
  let test_dir = ".test/cache_test_4"
  let _ = simplifile.create_directory_all(test_dir)
  let source = test_dir <> "/test.lustre"
  let output = test_dir <> "/test.gleam"

  let _ = simplifile.write(source, "<div>Hello</div>")
  let _ =
    simplifile.write(output, "// Not a generated file\npub fn render() { }")

  let result = cache.needs_regeneration(source, output)
  should.be_true(result)
  // Invalid header, regenerate

  let _ = simplifile.delete(test_dir)
}

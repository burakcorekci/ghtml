# Task 004: Cache Module

## Description
Implement hash-based caching in `cache.gleam`. This module calculates SHA-256 hashes of source files, extracts hashes from generated files, and determines if regeneration is needed.

## Dependencies
- Task 001: Project Setup

## Success Criteria
1. `hash_content/1` produces consistent SHA-256 hashes
2. `extract_hash/1` correctly parses hash from generated file headers
3. `needs_regeneration/2` correctly determines when to regenerate
4. Hash format matches plan specification (lowercase hex)
5. All edge cases are handled (missing files, invalid headers)

## Implementation Steps

### 1. Implement hash_content
```gleam
import gleam/crypto
import gleam/bit_array
import gleam/string
import gleam/list
import simplifile

pub fn hash_content(content: String) -> String {
  content
  |> bit_array.from_string()
  |> crypto.hash(crypto.Sha256, _)
  |> bit_array.base16_encode()
  |> string.lowercase()
}
```

### 2. Implement extract_hash
```gleam
pub fn extract_hash(generated_content: String) -> Result(String, Nil) {
  generated_content
  |> string.split("\n")
  |> list.find_map(fn(line) {
    case string.starts_with(line, "// @hash ") {
      True -> Ok(string.drop_start(line, 9) |> string.trim())
      False -> Error(Nil)
    }
  })
}
```

### 3. Implement needs_regeneration
```gleam
pub fn needs_regeneration(source_path: String, output_path: String) -> Bool {
  case simplifile.read(source_path), simplifile.read(output_path) {
    Ok(source), Ok(existing) -> {
      let current_hash = hash_content(source)
      case extract_hash(existing) {
        Ok(stored_hash) -> current_hash != stored_hash
        Error(_) -> True  // No valid hash found, regenerate
      }
    }
    Ok(_), Error(_) -> True   // Output doesn't exist, generate
    Error(_), _ -> False      // Source doesn't exist, skip
  }
}
```

### 4. Implement generate_header (helper for codegen)
```gleam
pub fn generate_header(source_filename: String, hash: String) -> String {
  "// @generated from " <> source_filename <> "\n"
  <> "// @hash " <> hash <> "\n"
  <> "// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen\n"
}
```

### 5. Implement is_generated (check if file was generated)
```gleam
pub fn is_generated(content: String) -> Bool {
  string.starts_with(content, "// @generated from ")
}
```

## Test Cases

### Test File: `test/cache_test.gleam`

```gleam
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
  let is_hex = string.to_graphemes(hash)
    |> list.all(fn(c) {
      string.contains("0123456789abcdef", c)
    })
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
  let content = "// @generated from test.lustre
// @hash abc123def456
// DO NOT EDIT

pub fn render() { }
"
  let result = cache.extract_hash(content)
  should.equal(result, Ok("abc123def456"))
}

pub fn extract_hash_with_extra_whitespace_test() {
  let content = "// @generated from test.lustre
// @hash   abc123def456
// DO NOT EDIT
"
  let result = cache.extract_hash(content)
  should.equal(result, Ok("abc123def456"))
}

pub fn extract_hash_missing_test() {
  let content = "// Some other file
pub fn render() { }
"
  let result = cache.extract_hash(content)
  should.equal(result, Error(Nil))
}

pub fn extract_hash_no_hash_line_test() {
  let content = "// @generated from test.lustre
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
  let content = "// @generated from test.lustre
// @hash abc123
pub fn render() { }
"
  should.be_true(cache.is_generated(content))
}

pub fn is_generated_false_test() {
  let content = "// This is a regular file
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
  let _ = simplifile.write(output, "// @generated from test.lustre\n// @hash " <> hash <> "\n")

  let result = cache.needs_regeneration(source, output)
  should.be_false(result)  // Hashes match, no regeneration needed

  let _ = simplifile.delete(test_dir)
}

pub fn needs_regeneration_different_hash_test() {
  let test_dir = ".test/cache_test_3"
  let _ = simplifile.create_directory_all(test_dir)
  let source = test_dir <> "/test.lustre"
  let output = test_dir <> "/test.gleam"

  let _ = simplifile.write(source, "<div>Hello</div>")
  let _ = simplifile.write(output, "// @generated from test.lustre\n// @hash oldhash123\n")

  let result = cache.needs_regeneration(source, output)
  should.be_true(result)  // Hashes differ, regeneration needed

  let _ = simplifile.delete(test_dir)
}

pub fn needs_regeneration_no_source_test() {
  let result = cache.needs_regeneration(
    ".test/nonexistent.lustre",
    ".test/nonexistent.gleam",
  )
  should.be_false(result)  // No source, don't try to regenerate
}

pub fn needs_regeneration_invalid_output_header_test() {
  let test_dir = ".test/cache_test_4"
  let _ = simplifile.create_directory_all(test_dir)
  let source = test_dir <> "/test.lustre"
  let output = test_dir <> "/test.gleam"

  let _ = simplifile.write(source, "<div>Hello</div>")
  let _ = simplifile.write(output, "// Not a generated file\npub fn render() { }")

  let result = cache.needs_regeneration(source, output)
  should.be_true(result)  // Invalid header, regenerate

  let _ = simplifile.delete(test_dir)
}
```

## Verification Checklist
- [x] `gleam build` succeeds
- [x] `gleam test` passes all cache tests
- [x] Hash output is correct format (64 char lowercase hex)
- [x] Known hash values match expected
- [x] Missing file cases handled correctly
- [x] Invalid header cases handled correctly

## Notes
- The hash is of the source `.lustre` file content only
- Use SHA-256 for good collision resistance
- The header format must match exactly for extraction to work
- Consider what happens with binary content (though templates should be text)

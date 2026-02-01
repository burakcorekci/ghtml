//// Cache management for incremental rebuilds.
////
//// Uses SHA-256 hashing to detect changes in source templates and skip
//// regeneration when files are unchanged.

import gleam/bit_array
import gleam/crypto
import gleam/list
import gleam/string
import simplifile

/// Calculate SHA-256 hash of content, returning lowercase hex string
pub fn hash_content(content: String) -> String {
  content
  |> bit_array.from_string()
  |> crypto.hash(crypto.Sha256, _)
  |> bit_array.base16_encode()
  |> string.lowercase()
}

/// Extract the hash from a generated file's header
/// Returns Ok(hash) if found, Error(Nil) if not present
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

/// Check if a source file needs regeneration based on hash comparison
/// Returns True if regeneration is needed, False otherwise
pub fn needs_regeneration(source_path: String, output_path: String) -> Bool {
  case simplifile.read(source_path), simplifile.read(output_path) {
    Ok(source), Ok(existing) -> {
      let current_hash = hash_content(source)
      case extract_hash(existing) {
        Ok(stored_hash) -> current_hash != stored_hash
        Error(_) -> True
        // No valid hash found, regenerate
      }
    }
    Ok(_), Error(_) -> True
    // Output doesn't exist, generate
    Error(_), _ -> False
    // Source doesn't exist, skip
  }
}

/// Generate the standard header for generated files
pub fn generate_header(source_filename: String, hash: String) -> String {
  "// @generated from "
  <> source_filename
  <> "\n"
  <> "// @hash "
  <> hash
  <> "\n"
  <> "// DO NOT EDIT - regenerate with: gleam run -m ghtml\n"
}

/// Check if content appears to be from a generated file
pub fn is_generated(content: String) -> Bool {
  string.starts_with(content, "// @generated from ")
}

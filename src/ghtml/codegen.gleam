//// Gleam code generator from parsed templates.
////
//// This module provides the main entry point for code generation and re-exports
//// shared utilities for backwards compatibility. The actual code generation
//// is delegated to target modules (currently only Lustre).

import ghtml/shared
import ghtml/target/lustre
import ghtml/types.{type Template}

/// Generate Gleam code from a parsed template.
///
/// Currently delegates to the Lustre target. In the future, this will
/// support multiple targets via a Target parameter.
pub fn generate(template: Template, source_path: String, hash: String) -> String {
  lustre.generate(template, source_path, hash)
}

// === Re-exported Shared Utilities ===
// These are re-exported from ghtml/shared for backwards compatibility.

/// Extract the filename from a full path
pub fn extract_filename(path: String) -> String {
  shared.extract_filename(path)
}

/// Escape special characters in a string for Gleam code
pub fn escape_string(s: String) -> String {
  shared.escape_string(s)
}

/// Normalize whitespace by collapsing multiple spaces/tabs to single spaces.
/// Newlines are preserved (they will be escaped later).
pub fn normalize_whitespace(text: String) -> String {
  shared.normalize_whitespace(text)
}

/// Check if a string is blank (empty or only whitespace)
pub fn is_blank(text: String) -> Bool {
  shared.is_blank(text)
}

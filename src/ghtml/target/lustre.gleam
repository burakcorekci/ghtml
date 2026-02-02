//// Lustre Element target for ghtml code generation.
////
//// This module generates Gleam code that produces Lustre `Element(msg)` values.
//// It's the default target and provides full support for:
//// - Interactive client-side applications
//// - Server-side rendering via `element.to_string()`
//// - Event handlers (@click, @input, etc.)

import ghtml/types.{type Template}

/// Generate Gleam source code for the Lustre target.
///
/// This function will be populated in Task 004 when we extract
/// the codegen logic from the main codegen module.
pub fn generate(
  _template: Template,
  _source_path: String,
  _hash: String,
) -> String {
  todo as "Will be implemented in Task 004"
}

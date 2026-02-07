//// Code generation dispatcher.
////
//// Routes code generation to the appropriate target backend based on the
//// Target type. Adding a new target requires:
//// 1. New variant in types.Target
//// 2. New module in ghtml/target/
//// 3. New case branch in generate()

import ghtml/target/lustre
import ghtml/types.{type Target, type Template, Lustre}

/// Generate Gleam code from a parsed template using the specified target.
pub fn generate(
  template: Template,
  source_path: String,
  hash: String,
  target: Target,
) -> String {
  case target {
    Lustre -> lustre.generate(template, source_path, hash)
  }
}

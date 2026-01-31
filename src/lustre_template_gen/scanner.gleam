// File system scanner for template discovery

import gleam/list
import gleam/string
import simplifile

/// Directories that should be ignored when scanning for templates
const ignored_dirs = ["build", ".git", "node_modules", "_build", ".plan"]

/// Finds all .lustre template files in the given directory tree
pub fn find_lustre_files(root: String) -> List(String) {
  find_recursive(root, [], ".lustre")
}

/// Finds all .gleam files in the given directory tree
pub fn find_generated_files(root: String) -> List(String) {
  find_recursive(root, [], ".gleam")
}

/// Converts a .lustre path to its .gleam output equivalent
pub fn to_output_path(lustre_path: String) -> String {
  string.replace(lustre_path, ".lustre", ".gleam")
}

/// Converts a .gleam path back to its .lustre source equivalent
pub fn to_source_path(gleam_path: String) -> String {
  string.replace(gleam_path, ".gleam", ".lustre")
}

/// Recursively finds files with the given extension, skipping ignored directories
fn find_recursive(
  dir: String,
  acc: List(String),
  extension: String,
) -> List(String) {
  case simplifile.read_directory(dir) {
    Ok(entries) -> {
      list.fold(entries, acc, fn(acc, entry) {
        case list.contains(ignored_dirs, entry) {
          True -> acc
          False -> {
            let path = dir <> "/" <> entry
            case simplifile.is_directory(path) {
              Ok(True) -> find_recursive(path, acc, extension)
              _ ->
                case string.ends_with(entry, extension) {
                  True -> [path, ..acc]
                  False -> acc
                }
            }
          }
        }
      })
    }
    Error(_) -> acc
  }
}

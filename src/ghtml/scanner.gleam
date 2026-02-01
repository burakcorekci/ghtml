//// File system scanner for template discovery.
////
//// Recursively finds `.ghtml` template files and their generated `.gleam`
//// counterparts, excluding common build and dependency directories.

import ghtml/cache
import gleam/io
import gleam/list
import gleam/string
import simplifile

/// Directories that should be ignored when scanning for templates
const ignored_dirs = [
  "build", ".git", "node_modules", "_build", ".claude", "fixtures", "examples",
  "generated",
]

/// Finds all .ghtml template files in the given directory tree
pub fn find_ghtml_files(root: String) -> List(String) {
  find_recursive(root, [], ".ghtml")
}

/// Finds all .gleam files in the given directory tree
pub fn find_generated_files(root: String) -> List(String) {
  find_recursive(root, [], ".gleam")
}

/// Converts a .ghtml path to its .gleam output equivalent
pub fn to_output_path(ghtml_path: String) -> String {
  string.replace(ghtml_path, ".ghtml", ".gleam")
}

/// Converts a .gleam path back to its .ghtml source equivalent
pub fn to_source_path(gleam_path: String) -> String {
  string.replace(gleam_path, ".gleam", ".ghtml")
}

/// Find orphaned generated files (files with no matching .ghtml source).
/// This is a dry-run mode that returns the list of orphan paths without deleting.
pub fn find_orphans(root: String) -> List(String) {
  find_generated_files(root)
  |> list.filter(is_orphaned_generated_file)
}

/// Cleanup orphaned generated files (files with no matching .ghtml source).
/// Returns the number of files deleted.
pub fn cleanup_orphans(root: String) -> Int {
  find_orphans(root)
  |> list.fold(0, fn(count, path) {
    case simplifile.delete(path) {
      Ok(_) -> {
        io.println("Removed orphan: " <> path)
        count + 1
      }
      Error(_) -> {
        io.println("Failed to remove: " <> path)
        count
      }
    }
  })
}

/// Check if a .gleam file is a generated orphan (has header but no source)
fn is_orphaned_generated_file(gleam_path: String) -> Bool {
  case simplifile.read(gleam_path) {
    Ok(content) -> {
      case cache.is_generated(content) {
        True -> {
          // Check if source exists
          let source_path = to_source_path(gleam_path)
          case simplifile.is_file(source_path) {
            Ok(True) -> False
            _ -> True
          }
        }
        False -> False
      }
    }
    Error(_) -> False
  }
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

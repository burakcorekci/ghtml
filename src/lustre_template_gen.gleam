//// Lustre Template Generator - CLI entry point.
////
//// A preprocessor that converts `.lustre` template files into Gleam modules
//// with Lustre `Element(msg)` render functions.
////
//// ## Usage
////
//// ```sh
//// gleam run -m lustre_template_gen              # Generate all
//// gleam run -m lustre_template_gen -- force     # Force regenerate
//// gleam run -m lustre_template_gen -- watch     # Watch mode
//// gleam run -m lustre_template_gen -- clean     # Remove orphans
//// ```

import argv
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import lustre_template_gen/cache
import lustre_template_gen/codegen
import lustre_template_gen/parser
import lustre_template_gen/scanner
import lustre_template_gen/watcher
import simplifile

/// Statistics about a generation run
pub type GenerationStats {
  GenerationStats(generated: Int, skipped: Int, errors: Int)
}

/// CLI options parsed from command-line arguments
pub type CliOptions {
  CliOptions(force: Bool, clean_only: Bool, watch: Bool, root: String)
}

/// Parse command-line arguments into options
pub fn parse_options(args: List(String)) -> CliOptions {
  // Extract root directory from args (first non-flag argument, or ".")
  let root =
    args
    |> list.find(fn(arg) { !list.contains(["force", "clean", "watch"], arg) })
    |> result.unwrap(".")

  CliOptions(
    force: list.contains(args, "force"),
    clean_only: list.contains(args, "clean"),
    watch: list.contains(args, "watch"),
    root: root,
  )
}

/// Main entry point for the CLI
pub fn main() {
  let options = parse_options(argv.load().arguments)

  case options.clean_only {
    True -> run_clean(options.root)
    False -> run_generate(options.root, options)
  }
}

/// Run cleanup mode - remove orphaned generated files
fn run_clean(root: String) {
  let count = scanner.cleanup_orphans(root)
  io.println("Cleaned up " <> int.to_string(count) <> " orphaned files")
}

/// Run generation mode - scan and generate templates
fn run_generate(root: String, options: CliOptions) {
  io.println("Lustre Template Generator v0.1.0")
  io.println("")

  let stats = generate_all(root, options.force)

  io.println("")
  io.println("Generated: " <> int.to_string(stats.generated))
  io.println("Skipped (unchanged): " <> int.to_string(stats.skipped))

  case stats.errors > 0 {
    True -> io.println("Errors: " <> int.to_string(stats.errors))
    False -> Nil
  }

  // Cleanup orphans
  let orphans = scanner.cleanup_orphans(root)
  case orphans > 0 {
    True -> io.println("Removed orphans: " <> int.to_string(orphans))
    False -> Nil
  }

  // Watch mode if requested
  case options.watch {
    True -> {
      io.println("")
      let _subject = watcher.start_watching(root)
      // Keep the process alive until interrupted
      process.sleep_forever()
    }
    False -> Nil
  }
}

/// Generate all templates in the given directory
pub fn generate_all(root: String, force: Bool) -> GenerationStats {
  scanner.find_lustre_files(root)
  |> list.fold(GenerationStats(0, 0, 0), fn(stats, source_path) {
    let output_path = scanner.to_output_path(source_path)

    case force || cache.needs_regeneration(source_path, output_path) {
      True -> {
        case process_file(source_path, output_path) {
          Ok(_) -> GenerationStats(..stats, generated: stats.generated + 1)
          Error(_) -> GenerationStats(..stats, errors: stats.errors + 1)
        }
      }
      False -> {
        io.println("· " <> source_path <> " (unchanged)")
        GenerationStats(..stats, skipped: stats.skipped + 1)
      }
    }
  })
}

/// Process a single template file
fn process_file(source_path: String, output_path: String) -> Result(Nil, String) {
  case simplifile.read(source_path) {
    Ok(content) -> {
      let hash = cache.hash_content(content)
      case parser.parse(content) {
        Ok(template) -> {
          let gleam_code = codegen.generate(template, source_path, hash)
          case simplifile.write(output_path, gleam_code) {
            Ok(_) -> {
              io.println("✓ " <> source_path <> " → " <> output_path)
              Ok(Nil)
            }
            Error(_) -> {
              io.println("✗ Error writing " <> output_path)
              Error("Write error")
            }
          }
        }
        Error(errors) -> {
          io.println("✗ Parse errors in " <> source_path <> ":")
          io.println(parser.format_errors(errors, content))
          Error("Parse error")
        }
      }
    }
    Error(_) -> {
      io.println("✗ Error reading " <> source_path)
      Error("Read error")
    }
  }
}

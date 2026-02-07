//// File watcher for watch mode.
////
//// Monitors `.ghtml` files for changes and triggers automatic regeneration
//// of the corresponding Gleam modules. Uses OTP actors with polling-based
//// file watching.
////
//// ## Usage
////
//// ```gleam
//// let subject = watcher.start_watching(".")
//// // Later, to stop:
//// process.send(subject, watcher.Stop)
//// ```

import ghtml/cache
import ghtml/parser
import ghtml/scanner
import ghtml/target/lustre
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/string
import simplifile

/// Messages that can be sent to the watcher actor
pub type WatcherMessage {
  /// Initialize with the actor's own subject
  Init(Subject(WatcherMessage))
  /// Trigger a check for file changes
  Check
  /// Stop the watcher
  Stop
}

/// Internal state of the watcher actor
pub type WatcherState {
  WatcherState(
    /// Root directory to watch
    root: String,
    /// Map of file paths to their modification times
    file_mtimes: Dict(String, Int),
    /// Self subject for scheduling checks (set after actor starts)
    self_subject: Option(Subject(WatcherMessage)),
  )
}

/// Get the modification time of a file in seconds.
/// Returns Error(Nil) if the file doesn't exist or can't be accessed.
pub fn get_mtime(path: String) -> Result(Int, Nil) {
  case simplifile.file_info(path) {
    Ok(info) -> Ok(info.mtime_seconds)
    Error(_) -> Error(Nil)
  }
}

/// Get modification times for all .ghtml files in a directory tree.
pub fn get_all_mtimes(root: String) -> Dict(String, Int) {
  scanner.find_ghtml_files(root)
  |> list.filter_map(fn(path) {
    case get_mtime(path) {
      Ok(mtime) -> Ok(#(path, mtime))
      Error(_) -> Error(Nil)
    }
  })
  |> dict.from_list()
}

/// Start the watcher actor for a given root directory.
/// Returns a subject that can be used to send messages to the watcher.
pub fn start_watching(root: String) -> Subject(WatcherMessage) {
  let initial_mtimes = get_all_mtimes(root)
  let initial_state =
    WatcherState(root: root, file_mtimes: initial_mtimes, self_subject: None)

  let assert Ok(started) =
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start

  // Get the actual subject from the started actor
  let actor_subject = started.data

  // Initialize the actor with its own subject for self-scheduling
  process.send(actor_subject, Init(actor_subject))

  io.println("Watching for changes... (Ctrl+C to stop)")
  io.println("")

  actor_subject
}

/// Handle messages sent to the watcher actor
fn handle_message(
  state: WatcherState,
  message: WatcherMessage,
) -> actor.Next(WatcherState, WatcherMessage) {
  case message {
    Stop -> actor.stop()
    Init(subject) -> {
      // Store the subject and start checking
      let new_state = WatcherState(..state, self_subject: Some(subject))
      schedule_check(subject)
      actor.continue(new_state)
    }
    Check -> {
      let new_state = check_for_changes(state)
      actor.continue(new_state)
    }
  }
}

/// Schedule the next check after a delay
fn schedule_check(subject: Subject(WatcherMessage)) {
  // Check every 500ms for reasonable responsiveness
  process.send_after(subject, 500, Check)
  Nil
}

/// Check for file changes and process any that need updating
fn check_for_changes(state: WatcherState) -> WatcherState {
  let current_files = scanner.find_ghtml_files(state.root)
  let current_mtimes = get_all_mtimes(state.root)

  // Check for new or modified files
  list.each(current_files, fn(path) {
    let should_process = case dict.get(state.file_mtimes, path) {
      Error(_) -> {
        // New file
        io.println("New file: " <> path)
        True
      }
      Ok(old_mtime) -> {
        case dict.get(current_mtimes, path) {
          Ok(new_mtime) if new_mtime != old_mtime -> {
            // Modified file
            io.println("Modified: " <> path)
            True
          }
          _ -> False
        }
      }
    }

    case should_process {
      True -> process_single_file(path)
      False -> Nil
    }
  })

  // Check for deleted files
  dict.keys(state.file_mtimes)
  |> list.each(fn(old_path) {
    case list.contains(current_files, old_path) {
      False -> {
        io.println("Deleted: " <> old_path)
        let gleam_path = scanner.to_output_path(old_path)
        case simplifile.delete(gleam_path) {
          Ok(_) -> io.println("  Removed: " <> gleam_path)
          Error(_) -> Nil
        }
      }
      True -> Nil
    }
  })

  // Schedule next check
  case state.self_subject {
    Some(subject) -> schedule_check(subject)
    None -> Nil
  }

  WatcherState(..state, file_mtimes: current_mtimes)
}

/// Process a single template file, generating the corresponding Gleam code.
pub fn process_single_file(source_path: String) {
  let output_path = scanner.to_output_path(source_path)

  case simplifile.read(source_path) {
    Ok(content) -> {
      let hash = cache.hash_content(content)
      case parser.parse(content) {
        Ok(template) -> {
          let gleam_code = lustre.generate(template, source_path, hash)
          case simplifile.write(output_path, gleam_code) {
            Ok(_) -> io.println("  Generated: " <> output_path)
            Error(e) -> io.println("  Error writing: " <> string.inspect(e))
          }
        }
        Error(errors) -> {
          io.println("  Parse errors:")
          list.each(errors, fn(e) {
            io.println(
              "    Line "
              <> int.to_string(e.span.start.line)
              <> ": "
              <> e.message,
            )
          })
        }
      }
    }
    Error(e) -> io.println("  Error reading: " <> string.inspect(e))
  }
}

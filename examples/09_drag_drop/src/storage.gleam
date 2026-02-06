/// LocalStorage persistence for the Task Manager

import gleam/option.{type Option, None}

/// Get a value from localStorage
pub fn get(key: String) -> Option(String) {
  do_get(key)
}

@external(javascript, "./ffi.mjs", "getLocalStorage")
fn do_get(_key: String) -> Option(String) {
  None
}

/// Set a value in localStorage
pub fn set(key: String, value: String) -> Nil {
  do_set(key, value)
}

@external(javascript, "./ffi.mjs", "setLocalStorage")
fn do_set(_key: String, _value: String) -> Nil {
  Nil
}

/// Remove a value from localStorage
pub fn remove(key: String) -> Nil {
  do_remove(key)
}

@external(javascript, "./ffi.mjs", "removeLocalStorage")
fn do_remove(_key: String) -> Nil {
  Nil
}

/// Key for storing tasks
pub const tasks_key = "taskmanager_tasks"

/// Key for storing projects
pub const projects_key = "taskmanager_projects"

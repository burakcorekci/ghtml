/// Task Manager - Complete Example Application
///
/// This example demonstrates a production-quality task management application
/// built with Lustre templates. It showcases:
/// - All template features (if/each/case, events, attributes)
/// - Shoelace web components for UI
/// - Tailwind CSS for styling
/// - Responsive design (mobile, tablet, desktop)
/// - Comprehensive state management
/// - Component-based architecture

import components/common/empty_state
import components/common/toast
import components/dialogs/confirm_dialog
import components/dialogs/export_dialog
import components/filters/filter_bar
import components/layout/header
import components/layout/mobile_nav
import components/layout/sidebar
import components/tasks/kanban_board
import components/tasks/task_detail
import components/tasks/task_list
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model.{
  type Model, type Task, AddTaskDialog, All, ByProject, DeleteConfirmDialog,
  Done, EditTaskDialog, ExportDialog, InProgress, KanbanView, ListView, Todo,
}
import msg.{type Msg}
import update

/// Application entry point
pub fn main() {
  let app = lustre.simple(init, update.update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

/// Initialize the application model
fn init(_flags) -> Model {
  let dark_mode = get_dark_mode_preference()
  apply_dark_mode(dark_mode)
  model.Model(..model.initial_model(), dark_mode: dark_mode)
}

@external(javascript, "./ffi.mjs", "getDarkModePreference")
fn get_dark_mode_preference() -> Bool

@external(javascript, "./ffi.mjs", "applyDarkMode")
fn apply_dark_mode(_enabled: Bool) -> Nil

/// Main view function
fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class("min-h-screen bg-gray-50 dark:bg-gray-900"),
    ],
    [
    // Main layout container
    html.div([attribute.class("flex h-screen")], [
      // Sidebar (hidden on mobile)
      view_sidebar(model),
      // Main content area
      html.div([attribute.class("flex-1 flex flex-col overflow-hidden")], [
        // Header
        header.render(
          model.current_view,
          model.search_query,
          model.dark_mode,
          fn() { msg.ToggleSidebar },
          fn(v) { msg.SetView(v) },
          decode_input_value(msg.UpdateSearchQuery),
          fn() { msg.ToggleDarkMode },
          fn() { msg.OpenAddTaskDialog },
        ),
        // Main content
        html.main([attribute.class("flex-1 overflow-auto p-4 lg:p-6")], [
          view_content(model),
        ]),
      ]),
    ]),
    // Mobile bottom navigation
    html.div([attribute.class("lg:hidden fixed bottom-0 left-0 right-0")], [
      mobile_nav.render(model.current_view, fn(v) { msg.SetView(v) }, fn() {
        msg.OpenAddTaskDialog
      }),
    ]),
    // Task detail panel
    view_task_detail(model),
    // Dialogs
    view_dialogs(model),
    // Toast notifications
    view_toast(model),
  ])
}

/// Sidebar view with backdrop for mobile
fn view_sidebar(model: Model) -> Element(Msg) {
  html.div([], [
    // Mobile backdrop
    case model.sidebar_open {
      True ->
        html.div(
          [
            attribute.class(
              "fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden",
            ),
            event.on_click(msg.ToggleSidebar),
          ],
          [],
        )
      False -> html.text("")
    },
    // Sidebar
    html.aside(
      [
        attribute.class(
          "fixed inset-y-0 left-0 z-50 w-64 bg-white dark:bg-gray-800 transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:z-auto "
          <> case model.sidebar_open {
            True -> "translate-x-0"
            False -> "-translate-x-full"
          },
        ),
      ],
      [
        sidebar.render(
          model.projects,
          get_current_project_id(model),
          fn() { msg.DeselectProject },
          fn(id) { msg.SelectProject(id) },
          fn() { msg.CreateProject },
        ),
      ],
    ),
  ])
}

/// Main content based on current view
fn view_content(model: Model) -> Element(Msg) {
  let filtered_tasks = filter_tasks(model)

  case list.length(filtered_tasks) {
    0 -> view_empty_state()
    _ ->
      html.div([], [
        // Filter bar
        filter_bar.render(model.current_filter, fn(f) {
          msg.SetFilter(f)
        }, decode_sort_value()),
        // Tasks view
        case model.current_view {
          ListView ->
            task_list.render(
              filtered_tasks,
              model.selected_task_id,
              fn(id) { msg.SelectTask(id) },
            )
          KanbanView -> {
            let todo_tasks =
              list.filter(filtered_tasks, fn(t) { t.status == Todo })
            let in_progress_tasks =
              list.filter(filtered_tasks, fn(t) { t.status == InProgress })
            let done_tasks =
              list.filter(filtered_tasks, fn(t) { t.status == Done })
            kanban_board.render(
              todo_tasks,
              in_progress_tasks,
              done_tasks,
              fn(id) { msg.SelectTask(id) },
              fn(id) { decode.success(msg.DragStart(id)) },
              decode.success(msg.DragEnd),
              fn(status) { decode.success(msg.DragOverColumn(status)) },
              decode.success(msg.DragLeaveColumn),
              fn(status) { decode.success(msg.DropOnColumn(status)) },
            )
          }
        },
      ])
  }
}

/// Empty state when no tasks
fn view_empty_state() -> Element(Msg) {
  empty_state.render(
    "No tasks",
    "No tasks yet",
    "Create your first task to get started.",
    "Create Task",
    fn() { msg.OpenAddTaskDialog },
  )
}

/// Unified slide-out panel for view/create/edit modes
fn view_task_detail(model: Model) -> Element(Msg) {
  // Determine if panel should be open and what mode
  let panel_state = case model.dialog_open {
    AddTaskDialog -> Some(#("create", None))
    EditTaskDialog(id) -> Some(#("edit", find_task(model.tasks, id)))
    _ ->
      case model.selected_task_id {
        Some(id) -> Some(#("view", find_task(model.tasks, id)))
        None -> None
      }
  }

  case panel_state {
    Some(#(mode, maybe_task)) ->
      html.div([], [
        // Backdrop
        html.div(
          [
            attribute.class("fixed inset-0 bg-black bg-opacity-50 z-40"),
            event.on_click(case mode {
              "create" -> msg.CloseDialog
              "edit" -> msg.CloseDialog
              _ -> msg.DeselectTask
            }),
          ],
          [],
        ),
        // Panel
        html.div(
          [
            attribute.class(
              "fixed inset-y-0 right-0 z-50 w-full max-w-md bg-white dark:bg-gray-800 shadow-xl overflow-y-auto",
            ),
          ],
          [
            case mode {
              "create" -> view_task_form(model, "New Task", None)
              "edit" -> view_task_form(model, "Edit Task", maybe_task)
              _ ->
                case maybe_task {
                  Some(t) ->
                    task_detail.render(
                      t,
                      model.new_subtask_text,
                      model.editing_subtask_id,
                      model.editing_subtask_text,
                      fn() { msg.OpenEditTaskDialog(t.id) },
                      fn() { msg.OpenDeleteConfirmDialog(t.id) },
                      fn() { msg.ToggleTaskStatus(t.id) },
                      fn(subtask_id) { msg.ToggleSubtask(t.id, subtask_id) },
                      decode_input_value(msg.UpdateNewSubtaskText),
                      decode_subtask_enter(t.id),
                      fn() { msg.SubmitNewSubtask(t.id) },
                      fn(subtask_id) { msg.DeleteSubtask(t.id, subtask_id) },
                      fn(subtask_id, text) {
                        msg.StartEditSubtask(subtask_id, text)
                      },
                      decode_input_value(msg.UpdateEditSubtaskText),
                      fn(subtask_id) { msg.SaveEditSubtask(t.id, subtask_id) },
                      fn() { msg.CancelEditSubtask },
                      fn() { msg.DeselectTask },
                    )
                  None -> html.text("")
                }
            },
          ],
        ),
      ])
    None -> html.text("")
  }
}

/// Form view for create/edit modes
fn view_task_form(
  model: Model,
  title: String,
  _task: Option(Task),
) -> Element(Msg) {
  html.div([attribute.class("p-6")], [
    // Header
    html.div([attribute.class("flex items-center justify-between mb-6")], [
      html.h2(
        [attribute.class("text-xl font-semibold text-gray-900 dark:text-white")],
        [html.text(title)],
      ),
      html.button(
        [
          attribute.class(
            "text-gray-400 hover:text-gray-600 dark:hover:text-gray-200",
          ),
          event.on_click(msg.CloseDialog),
        ],
        [html.span([attribute.class("text-xl")], [html.text("X")])],
      ),
    ]),
    // Form fields
    html.div([attribute.class("space-y-4")], [
      // Title
      html.div([], [
        html.label(
          [
            attribute.class(
              "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1",
            ),
          ],
          [html.text("Title")],
        ),
        element.element("sl-input", [
          attribute.attribute("value", model.form.title),
          attribute.attribute("placeholder", "Task title"),
          event.on("sl-input", decode_input_value(msg.UpdateFormTitle)),
        ], []),
      ]),
      // Description
      html.div([], [
        html.label(
          [
            attribute.class(
              "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1",
            ),
          ],
          [html.text("Description")],
        ),
        element.element("sl-textarea", [
          attribute.attribute("value", model.form.description),
          attribute.attribute("placeholder", "Add details..."),
          attribute.attribute("rows", "3"),
          event.on("sl-input", decode_input_value(msg.UpdateFormDescription)),
        ], []),
      ]),
      // Priority
      html.div([], [
        html.label(
          [
            attribute.class(
              "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1",
            ),
          ],
          [html.text("Priority")],
        ),
        element.element(
          "sl-select",
          [
            attribute.attribute("value", model.priority_to_string(model.form.priority)),
            attribute.attribute("hoist", ""),
            event.on(
              "sl-change",
              decode_input_value(fn(s) {
                msg.UpdateFormPriority(model.priority_from_string(s))
              }),
            ),
          ],
          [
            element.element("sl-option", [attribute.attribute("value", "none")], [
              html.text("No Priority"),
            ]),
            element.element("sl-option", [attribute.attribute("value", "low")], [
              html.text("Low"),
            ]),
            element.element("sl-option", [attribute.attribute("value", "medium")], [
              html.text("Medium"),
            ]),
            element.element("sl-option", [attribute.attribute("value", "high")], [
              html.text("High"),
            ]),
          ],
        ),
      ]),
      // Due Date
      html.div([], [
        html.label(
          [
            attribute.class(
              "block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1",
            ),
          ],
          [html.text("Due Date")],
        ),
        element.element("sl-input", [
          attribute.attribute("type", "date"),
          attribute.attribute("value", case model.form.due_date {
            Some(d) -> d
            None -> ""
          }),
          event.on("sl-input", decode_input_value(msg.UpdateFormDueDate)),
        ], []),
      ]),
    ]),
    // Actions
    html.div(
      [attribute.class("flex gap-2 pt-6 mt-6 border-t border-gray-200 dark:border-gray-700")],
      [
        element.element("sl-button", [
          attribute.attribute("variant", "default"),
          event.on_click(msg.CloseDialog),
        ], [html.text("Cancel")]),
        element.element("sl-button", [
          attribute.attribute("variant", "primary"),
          event.on_click(msg.SubmitForm),
        ], [
          html.text(case model.dialog_open {
            EditTaskDialog(_) -> "Save Changes"
            _ -> "Create Task"
          }),
        ]),
      ],
    ),
  ])
}

/// Find a task by ID
fn find_task(tasks: List(Task), id: String) -> Option(Task) {
  list.find(tasks, fn(t) { t.id == id })
  |> option.from_result
}

/// Decoder for close dialog events
fn close_dialog_decoder() -> decode.Decoder(Msg) {
  decode.success(msg.CloseDialog)
}

/// Dialog views based on current dialog state
fn view_dialogs(model: Model) -> Element(Msg) {
  html.div([], [
    // Delete confirmation dialog
    confirm_dialog.render(
      case model.dialog_open {
        DeleteConfirmDialog(_) -> True
        _ -> False
      },
      "Delete Task",
      "Are you sure you want to delete this task? This action cannot be undone.",
      "Delete",
      fn() {
        case model.dialog_open {
          DeleteConfirmDialog(id) -> msg.DeleteTask(id)
          _ -> msg.CloseDialog
        }
      },
      fn() { msg.CloseDialog },
      close_dialog_decoder(),
    ),
    // Export dialog
    export_dialog.render(
      model.dialog_open == ExportDialog,
      fn() { msg.ExportTasks },
      fn() { msg.ImportTasks("") },
      fn() { msg.ClearAllData },
      fn() { msg.CloseDialog },
      close_dialog_decoder(),
    ),
  ])
}

/// Toast notification view
fn view_toast(model: Model) -> Element(Msg) {
  case model.toast {
    Some(#(message, toast_type)) ->
      toast.render(message, toast_type, True, fn() { msg.DismissToast })
    None -> html.text("")
  }
}

/// Get current project ID from filter
fn get_current_project_id(model: Model) -> Option(String) {
  case model.current_filter {
    ByProject(id) -> Some(id)
    _ -> None
  }
}

/// Filter tasks based on current filter and search
fn filter_tasks(model: Model) -> List(Task) {
  let by_filter =
    list.filter(model.tasks, fn(t) {
      case model.current_filter {
        All -> True
        ByProject(id) -> t.project_id == Some(id)
        model.Today -> False
        model.Overdue -> False
      }
    })

  case model.search_query {
    "" -> by_filter
    query ->
      list.filter(by_filter, fn(t) { contains_ignore_case(t.title, query) })
  }
}

/// Case-insensitive string contains check
fn contains_ignore_case(haystack: String, needle: String) -> Bool {
  let h = string_lowercase(haystack)
  let n = string_lowercase(needle)
  string_contains(h, n)
}

@external(javascript, "./ffi.mjs", "stringContains")
fn string_contains(_haystack: String, _needle: String) -> Bool {
  False
}

@external(javascript, "./ffi.mjs", "stringLowercase")
fn string_lowercase(s: String) -> String {
  s
}

/// Decoder for extracting input value from Shoelace events
fn decode_input_value(to_msg: fn(String) -> msg) -> decode.Decoder(msg) {
  decode.at(["target", "value"], decode.string)
  |> decode.map(to_msg)
}

/// Decoder for sort selection
fn decode_sort_value() -> decode.Decoder(Msg) {
  decode.at(["target", "value"], decode.string)
  |> decode.map(fn(s) {
    case s {
      "created" -> msg.SetSort(model.SortByCreated)
      "due_date" -> msg.SetSort(model.SortByDueDate)
      "priority" -> msg.SetSort(model.SortByPriority)
      "title" -> msg.SetSort(model.SortByTitle)
      _ -> msg.SetSort(model.SortByCreated)
    }
  })
}

/// Decoder for adding subtask on Enter key
fn decode_subtask_enter(task_id: String) -> decode.Decoder(Msg) {
  use key <- decode.then(decode.at(["key"], decode.string))
  case key {
    "Enter" -> decode.success(msg.SubmitNewSubtask(task_id))
    _ -> decode.success(msg.NoOp)  // Ignore other keys
  }
}

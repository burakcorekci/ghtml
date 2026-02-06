/// Update logic for the Task Manager application

import gleam/list
import gleam/option.{None, Some}
import gleam/string
import model.{
  type FormState, type Model, type Task, AddTaskDialog, All, DeleteConfirmDialog,
  Done, EditTaskDialog, FormState, InProgress, Model, NoDialog, Subtask, Task,
  Todo,
}
import msg.{type Msg}

/// Update the model based on a message
pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    // No-op - return model unchanged
    msg.NoOp -> model

    // Navigation
    msg.ToggleSidebar -> Model(..model, sidebar_open: !model.sidebar_open)

    msg.ToggleDarkMode -> {
      let new_dark_mode = !model.dark_mode
      apply_dark_mode(new_dark_mode)
      Model(..model, dark_mode: new_dark_mode)
    }

    msg.SetView(view) -> Model(..model, current_view: view)

    msg.SetFilter(filter) -> Model(..model, current_filter: filter)

    msg.SetSort(sort) -> Model(..model, sort_by: sort)

    // Search
    msg.UpdateSearchQuery(query) -> Model(..model, search_query: query)

    msg.ClearSearch -> Model(..model, search_query: "")

    // Task actions
    msg.SelectTask(id) -> Model(..model, selected_task_id: Some(id))

    msg.DeselectTask -> Model(..model, selected_task_id: None)

    msg.CreateTask -> {
      let new_task = create_task_from_form(model)
      Model(
        ..model,
        tasks: [new_task, ..model.tasks],
        dialog_open: NoDialog,
        form: model.empty_form(),
        selected_task_id: Some(new_task.id),
        toast: Some(#("Task created successfully", model.Success)),
      )
    }

    msg.UpdateTask(id) -> {
      let updated_tasks =
        list.map(model.tasks, fn(t) {
          case t.id == id {
            True -> update_task_from_form(t, model.form)
            False -> t
          }
        })
      Model(
        ..model,
        tasks: updated_tasks,
        dialog_open: NoDialog,
        form: model.empty_form(),
        toast: Some(#("Task updated successfully", model.Success)),
      )
    }

    msg.DeleteTask(id) -> {
      let filtered_tasks = list.filter(model.tasks, fn(t) { t.id != id })
      Model(
        ..model,
        tasks: filtered_tasks,
        dialog_open: NoDialog,
        selected_task_id: None,
        toast: Some(#("Task deleted", model.Info)),
      )
    }

    msg.ToggleTaskStatus(id) -> {
      let updated_tasks =
        list.map(model.tasks, fn(t) {
          case t.id == id {
            True -> Task(..t, status: next_status(t.status))
            False -> t
          }
        })
      Model(..model, tasks: updated_tasks)
    }

    msg.SetTaskStatus(id, status) -> {
      let updated_tasks =
        list.map(model.tasks, fn(t) {
          case t.id == id {
            True -> Task(..t, status: status)
            False -> t
          }
        })
      Model(..model, tasks: updated_tasks)
    }

    // Drag and drop actions
    msg.DragStart(id) ->
      Model(..model, dragging_task_id: Some(id))

    msg.DragEnd ->
      Model(..model, dragging_task_id: None, drop_target_column: None)

    msg.DragOverColumn(status) ->
      Model(..model, drop_target_column: Some(status))

    msg.DragLeaveColumn ->
      Model(..model, drop_target_column: None)

    msg.DropOnColumn(status) -> {
      case model.dragging_task_id {
        Some(id) -> {
          let updated_tasks =
            list.map(model.tasks, fn(t) {
              case t.id == id {
                True -> Task(..t, status: status)
                False -> t
              }
            })
          Model(
            ..model,
            tasks: updated_tasks,
            dragging_task_id: None,
            drop_target_column: None,
          )
        }
        None -> Model(..model, dragging_task_id: None, drop_target_column: None)
      }
    }

    // Subtask actions
    msg.ToggleSubtask(task_id, subtask_id) -> {
      let updated_tasks =
        list.map(model.tasks, fn(t) {
          case t.id == task_id {
            True ->
              Task(
                ..t,
                subtasks: list.map(t.subtasks, fn(s) {
                  case s.id == subtask_id {
                    True -> Subtask(..s, completed: !s.completed)
                    False -> s
                  }
                }),
              )
            False -> t
          }
        })
      Model(..model, tasks: updated_tasks)
    }

    msg.UpdateNewSubtaskText(text) ->
      Model(..model, new_subtask_text: text)

    msg.SubmitNewSubtask(task_id) -> {
      case model.new_subtask_text {
        "" -> model
        text -> {
          let updated_tasks =
            list.map(model.tasks, fn(t) {
              case t.id == task_id {
                True -> {
                  let new_subtask =
                    Subtask(
                      id: task_id <> "-" <> generate_id(),
                      text: text,
                      completed: False,
                    )
                  Task(..t, subtasks: list.append(t.subtasks, [new_subtask]))
                }
                False -> t
              }
            })
          Model(..model, tasks: updated_tasks, new_subtask_text: "")
        }
      }
    }

    msg.AddSubtask(task_id, text) -> {
      case text {
        "" -> model
        _ -> {
          let updated_tasks =
            list.map(model.tasks, fn(t) {
              case t.id == task_id {
                True -> {
                  let new_subtask =
                    Subtask(
                      id: task_id <> "-" <> generate_id(),
                      text: text,
                      completed: False,
                    )
                  Task(..t, subtasks: list.append(t.subtasks, [new_subtask]))
                }
                False -> t
              }
            })
          Model(..model, tasks: updated_tasks)
        }
      }
    }

    msg.DeleteSubtask(task_id, subtask_id) -> {
      let updated_tasks =
        list.map(model.tasks, fn(t) {
          case t.id == task_id {
            True ->
              Task(
                ..t,
                subtasks: list.filter(t.subtasks, fn(s) { s.id != subtask_id }),
              )
            False -> t
          }
        })
      Model(..model, tasks: updated_tasks)
    }

    msg.StartEditSubtask(subtask_id, current_text) ->
      Model(
        ..model,
        editing_subtask_id: Some(subtask_id),
        editing_subtask_text: current_text,
      )

    msg.UpdateEditSubtaskText(text) ->
      Model(..model, editing_subtask_text: text)

    msg.SaveEditSubtask(task_id, subtask_id) -> {
      case model.editing_subtask_text {
        "" -> Model(..model, editing_subtask_id: None, editing_subtask_text: "")
        text -> {
          let updated_tasks =
            list.map(model.tasks, fn(t) {
              case t.id == task_id {
                True ->
                  Task(
                    ..t,
                    subtasks: list.map(t.subtasks, fn(s) {
                      case s.id == subtask_id {
                        True -> Subtask(..s, text: text)
                        False -> s
                      }
                    }),
                  )
                False -> t
              }
            })
          Model(
            ..model,
            tasks: updated_tasks,
            editing_subtask_id: None,
            editing_subtask_text: "",
          )
        }
      }
    }

    msg.CancelEditSubtask ->
      Model(..model, editing_subtask_id: None, editing_subtask_text: "")

    // Project actions
    msg.SelectProject(id) -> Model(..model, current_filter: model.ByProject(id))

    msg.DeselectProject -> Model(..model, current_filter: All)

    msg.CreateProject -> model

    // Dialog actions
    msg.OpenAddTaskDialog ->
      Model(..model, dialog_open: AddTaskDialog, form: model.empty_form())

    msg.OpenEditTaskDialog(id) -> {
      let task = find_task(model.tasks, id)
      case task {
        Some(t) ->
          Model(
            ..model,
            dialog_open: EditTaskDialog(id),
            form: form_from_task(t),
          )
        None -> model
      }
    }

    msg.OpenDeleteConfirmDialog(id) ->
      Model(..model, dialog_open: DeleteConfirmDialog(id))

    msg.OpenExportDialog -> Model(..model, dialog_open: model.ExportDialog)

    msg.CloseDialog -> Model(..model, dialog_open: NoDialog)

    // Form actions
    msg.UpdateFormTitle(title) ->
      Model(..model, form: FormState(..model.form, title: title))

    msg.UpdateFormDescription(desc) ->
      Model(..model, form: FormState(..model.form, description: desc))

    msg.UpdateFormPriority(priority) ->
      Model(..model, form: FormState(..model.form, priority: priority))

    msg.UpdateFormDueDate(date) -> {
      let due =
        case date {
          "" -> None
          d -> Some(d)
        }
      Model(..model, form: FormState(..model.form, due_date: due))
    }

    msg.UpdateFormProject(id) ->
      Model(..model, form: FormState(..model.form, project_id: Some(id)))

    msg.ClearFormProject ->
      Model(..model, form: FormState(..model.form, project_id: None))

    msg.SubmitForm ->
      case model.dialog_open {
        AddTaskDialog -> update(model, msg.CreateTask)
        EditTaskDialog(id) -> update(model, msg.UpdateTask(id))
        _ -> model
      }

    // Toast actions
    msg.ShowToast(message, toast_type) ->
      Model(..model, toast: Some(#(message, toast_type)))

    msg.DismissToast -> Model(..model, toast: None)

    // Bulk actions
    msg.CompleteAllTasks -> {
      let updated_tasks = list.map(model.tasks, fn(t) { Task(..t, status: Done) })
      Model(
        ..model,
        tasks: updated_tasks,
        toast: Some(#("All tasks completed", model.Success)),
      )
    }

    msg.DeleteCompletedTasks -> {
      let filtered = list.filter(model.tasks, fn(t) { t.status != Done })
      Model(
        ..model,
        tasks: filtered,
        toast: Some(#("Completed tasks deleted", model.Info)),
      )
    }

    // Persistence
    msg.ExportTasks -> model

    msg.ImportTasks(_) -> model

    msg.ClearAllData ->
      Model(
        ..model,
        tasks: [],
        projects: [],
        toast: Some(#("All data cleared", model.Warning)),
      )

    // Keyboard shortcuts
    msg.HandleKeyDown(key) ->
      case key {
        "n" -> update(model, msg.OpenAddTaskDialog)
        "Escape" ->
          case model.dialog_open {
            NoDialog -> Model(..model, selected_task_id: None)
            _ -> Model(..model, dialog_open: NoDialog)
          }
        "/" -> model
        _ -> model
      }
  }
}

/// Get the next status in the workflow
fn next_status(status: model.TaskStatus) -> model.TaskStatus {
  case status {
    Todo -> InProgress
    InProgress -> Done
    Done -> Todo
  }
}

/// Create a new task from form state
fn create_task_from_form(model: Model) -> Task {
  Task(
    id: generate_id(),
    title: model.form.title,
    description: model.form.description,
    status: Todo,
    priority: model.form.priority,
    due_date: model.form.due_date,
    project_id: model.form.project_id,
    subtasks: [],
    created_at: "2024-01-20",
    updated_at: "2024-01-20",
  )
}

/// Update a task with form state
fn update_task_from_form(task: Task, form: FormState) -> Task {
  Task(
    ..task,
    title: form.title,
    description: form.description,
    priority: form.priority,
    due_date: form.due_date,
    project_id: form.project_id,
    updated_at: "2024-01-20",
  )
}

/// Create form state from a task
fn form_from_task(task: Task) -> FormState {
  FormState(
    title: task.title,
    description: task.description,
    priority: task.priority,
    due_date: task.due_date,
    project_id: task.project_id,
  )
}

/// Find a task by ID
fn find_task(tasks: List(Task), id: String) -> option.Option(Task) {
  case tasks {
    [] -> None
    [first, ..rest] ->
      case first.id == id {
        True -> Some(first)
        False -> find_task(rest, id)
      }
  }
}

/// Generate a simple ID (in real app, use UUID)
fn generate_id() -> String {
  string.inspect(erlang_now())
}

@external(javascript, "./ffi.mjs", "now")
fn erlang_now() -> Int

@external(javascript, "./ffi.mjs", "applyDarkMode")
fn apply_dark_mode(_enabled: Bool) -> Nil

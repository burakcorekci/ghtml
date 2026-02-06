/// Types for the Task Manager application

import gleam/option.{type Option}

/// A single task with all its properties
pub type Task {
  Task(
    id: String,
    title: String,
    description: String,
    status: TaskStatus,
    priority: Priority,
    due_date: Option(String),
    project_id: Option(String),
    subtasks: List(Subtask),
    created_at: String,
    updated_at: String,
  )
}

/// A subtask/checklist item within a task
pub type Subtask {
  Subtask(id: String, text: String, completed: Bool)
}

/// Task workflow status
pub type TaskStatus {
  Todo
  InProgress
  Done
}

/// Priority levels for tasks
pub type Priority {
  High
  Medium
  Low
  NoPriority
}

/// A project/category for organizing tasks
pub type Project {
  Project(id: String, name: String, color: String, task_count: Int)
}

/// View mode for the task list
pub type View {
  ListView
  KanbanView
}

/// Filter options for tasks
pub type Filter {
  All
  ByProject(String)
  Today
  Overdue
}

/// Sort options for tasks
pub type SortBy {
  SortByCreated
  SortByDueDate
  SortByPriority
  SortByTitle
}

/// Toast notification types
pub type ToastType {
  Success
  Error
  Warning
  Info
}

/// Dialog states
pub type DialogState {
  NoDialog
  AddTaskDialog
  EditTaskDialog(String)
  DeleteConfirmDialog(String)
  ExportDialog
}

/// Form state for task creation/editing
pub type FormState {
  FormState(
    title: String,
    description: String,
    priority: Priority,
    due_date: Option(String),
    project_id: Option(String),
  )
}

/// Main application model
pub type Model {
  Model(
    tasks: List(Task),
    projects: List(Project),
    current_view: View,
    current_filter: Filter,
    sort_by: SortBy,
    search_query: String,
    sidebar_open: Bool,
    selected_task_id: Option(String),
    editing_task: Option(Task),
    dialog_open: DialogState,
    toast: Option(#(String, ToastType)),
    form: FormState,
    dark_mode: Bool,
    new_subtask_text: String,
    editing_subtask_id: Option(String),
    editing_subtask_text: String,
  )
}

/// Create an empty form state
pub fn empty_form() -> FormState {
  FormState(
    title: "",
    description: "",
    priority: NoPriority,
    due_date: option.None,
    project_id: option.None,
  )
}

/// Create an initial model with sample data
pub fn initial_model() -> Model {
  Model(
    tasks: sample_tasks(),
    projects: sample_projects(),
    current_view: ListView,
    current_filter: All,
    sort_by: SortByCreated,
    search_query: "",
    sidebar_open: False,
    selected_task_id: option.None,
    editing_task: option.None,
    dialog_open: NoDialog,
    toast: option.None,
    form: empty_form(),
    dark_mode: False,
    new_subtask_text: "",
    editing_subtask_id: option.None,
    editing_subtask_text: "",
  )
}

/// Sample tasks for initial state
fn sample_tasks() -> List(Task) {
  [
    Task(
      id: "1",
      title: "Set up project structure",
      description: "Create the initial folder structure and configuration files",
      status: Done,
      priority: High,
      due_date: option.Some("2024-01-15"),
      project_id: option.Some("proj-1"),
      subtasks: [
        Subtask(id: "1-1", text: "Create directories", completed: True),
        Subtask(id: "1-2", text: "Add configuration", completed: True),
      ],
      created_at: "2024-01-10",
      updated_at: "2024-01-15",
    ),
    Task(
      id: "2",
      title: "Implement core features",
      description: "Build the main functionality of the application",
      status: InProgress,
      priority: High,
      due_date: option.Some("2024-01-20"),
      project_id: option.Some("proj-1"),
      subtasks: [
        Subtask(id: "2-1", text: "Task CRUD operations", completed: True),
        Subtask(id: "2-2", text: "Filtering and search", completed: False),
        Subtask(id: "2-3", text: "Persistence", completed: False),
      ],
      created_at: "2024-01-12",
      updated_at: "2024-01-18",
    ),
    Task(
      id: "3",
      title: "Write documentation",
      description: "Create comprehensive documentation for the project",
      status: Todo,
      priority: Medium,
      due_date: option.Some("2024-01-25"),
      project_id: option.Some("proj-1"),
      subtasks: [],
      created_at: "2024-01-14",
      updated_at: "2024-01-14",
    ),
    Task(
      id: "4",
      title: "Review pull requests",
      description: "Review and merge pending PRs",
      status: Todo,
      priority: Low,
      due_date: option.None,
      project_id: option.Some("proj-2"),
      subtasks: [],
      created_at: "2024-01-16",
      updated_at: "2024-01-16",
    ),
    Task(
      id: "5",
      title: "Fix login bug",
      description: "Users are unable to log in on mobile devices",
      status: InProgress,
      priority: High,
      due_date: option.Some("2024-01-18"),
      project_id: option.Some("proj-2"),
      subtasks: [
        Subtask(id: "5-1", text: "Reproduce issue", completed: True),
        Subtask(id: "5-2", text: "Identify root cause", completed: True),
        Subtask(id: "5-3", text: "Implement fix", completed: False),
        Subtask(id: "5-4", text: "Test on devices", completed: False),
      ],
      created_at: "2024-01-17",
      updated_at: "2024-01-18",
    ),
  ]
}

/// Sample projects for initial state
fn sample_projects() -> List(Project) {
  [
    Project(id: "proj-1", name: "Task Manager", color: "#3b82f6", task_count: 3),
    Project(id: "proj-2", name: "Bug Fixes", color: "#ef4444", task_count: 2),
  ]
}

/// Convert priority to string for display
pub fn priority_to_string(priority: Priority) -> String {
  case priority {
    High -> "high"
    Medium -> "medium"
    Low -> "low"
    NoPriority -> "none"
  }
}

/// Parse priority from string
pub fn priority_from_string(s: String) -> Priority {
  case s {
    "high" -> High
    "medium" -> Medium
    "low" -> Low
    _ -> NoPriority
  }
}

/// Convert status to string
pub fn status_to_string(status: TaskStatus) -> String {
  case status {
    Todo -> "todo"
    InProgress -> "in-progress"
    Done -> "done"
  }
}

/// Count completed subtasks
pub fn completed_subtasks(task: Task) -> Int {
  count_completed(task.subtasks, 0)
}

fn count_completed(subtasks: List(Subtask), acc: Int) -> Int {
  case subtasks {
    [] -> acc
    [first, ..rest] ->
      case first.completed {
        True -> count_completed(rest, acc + 1)
        False -> count_completed(rest, acc)
      }
  }
}

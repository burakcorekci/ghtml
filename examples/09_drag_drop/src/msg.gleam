/// Message types for the Task Manager application

import model.{type Filter, type Priority, type SortBy, type TaskStatus, type View}

/// All application messages
pub type Msg {
  // No-op for ignored events
  NoOp

  // Navigation
  ToggleSidebar
  ToggleDarkMode
  SetView(View)
  SetFilter(Filter)
  SetSort(SortBy)

  // Search
  UpdateSearchQuery(String)
  ClearSearch

  // Task actions
  SelectTask(String)
  DeselectTask
  CreateTask
  UpdateTask(String)
  DeleteTask(String)
  ToggleTaskStatus(String)
  SetTaskStatus(String, TaskStatus)

  // Subtask actions
  ToggleSubtask(String, String)
  UpdateNewSubtaskText(String)
  SubmitNewSubtask(String)
  AddSubtask(String, String)
  DeleteSubtask(String, String)
  StartEditSubtask(String, String)
  UpdateEditSubtaskText(String)
  SaveEditSubtask(String, String)
  CancelEditSubtask

  // Project actions
  SelectProject(String)
  DeselectProject
  CreateProject

  // Dialog actions
  OpenAddTaskDialog
  OpenEditTaskDialog(String)
  OpenDeleteConfirmDialog(String)
  OpenExportDialog
  CloseDialog

  // Form actions
  UpdateFormTitle(String)
  UpdateFormDescription(String)
  UpdateFormPriority(Priority)
  UpdateFormDueDate(String)
  UpdateFormProject(String)
  ClearFormProject
  SubmitForm

  // Toast actions
  ShowToast(String, model.ToastType)
  DismissToast

  // Bulk actions
  CompleteAllTasks
  DeleteCompletedTasks

  // Persistence
  ExportTasks
  ImportTasks(String)
  ClearAllData

  // Drag and drop
  DragStart(String)
  DragEnd
  DragOver(TaskStatus)
  DragLeave
  DropTask(TaskStatus)

  // Keyboard shortcuts
  HandleKeyDown(String)
}

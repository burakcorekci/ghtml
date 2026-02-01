# Task 008: Create Complete Example - Production Task Manager

## Description

Create `examples/08_complete/` - a production-quality "Task Manager" application with responsive design, comprehensive features, and proper architecture. This serves as a reference implementation showing how to build real applications with Lustre templates.

## Dependencies

- 002: Attributes example (patterns for static/dynamic/boolean attrs)
- 003: Events example (both handler patterns)
- 004: Control flow example (if/each/case)
- 005: Shoelace example (web component integration)
- 006: Material Web example (alternative web components)
- 007: Tailwind example (utility-first styling)

## Success Criteria

1. Full-featured task management application
2. Responsive design (mobile, tablet, desktop)
3. Production-quality component architecture
4. Comprehensive state management
5. Keyboard navigation and accessibility
6. Persistent storage (localStorage)
7. All template features demonstrated in realistic context

## Features

### Core Functionality
- Create, read, update, delete tasks
- Task categories/projects
- Priority levels (High, Medium, Low, None)
- Due dates with overdue indicators
- Task status workflow (Todo → In Progress → Done)
- Subtasks/checklist items
- Search and filter
- Bulk actions (complete all, delete completed)

### UI/UX
- Responsive sidebar navigation (collapsible on mobile)
- Kanban board view option
- List view with sorting
- Empty states with helpful prompts
- Loading states
- Confirmation dialogs for destructive actions
- Toast notifications for feedback
- Keyboard shortcuts

### Data Persistence
- LocalStorage for task data
- Import/export as JSON

## Architecture

```
08_complete/
├── gleam.toml
├── README.md
├── assets/
│   └── styles.css           # Custom styles beyond Tailwind
└── src/
    ├── app.gleam            # Main entry, root component
    ├── model.gleam          # Application state types
    ├── msg.gleam            # All message types
    ├── update.gleam         # State update logic
    ├── storage.gleam        # LocalStorage persistence
    └── components/
        ├── layout/
        │   ├── app_shell.lustre       # Main layout wrapper
        │   ├── sidebar.lustre         # Navigation sidebar
        │   ├── header.lustre          # Top header bar
        │   └── mobile_nav.lustre      # Mobile bottom nav
        ├── tasks/
        │   ├── task_card.lustre       # Individual task card
        │   ├── task_list.lustre       # List of tasks
        │   ├── task_detail.lustre     # Full task view/edit
        │   ├── task_form.lustre       # Create/edit form
        │   ├── subtask_item.lustre    # Checklist item
        │   └── kanban_board.lustre    # Kanban view
        ├── filters/
        │   ├── filter_bar.lustre      # Filter controls
        │   ├── search_input.lustre    # Search box
        │   └── sort_dropdown.lustre   # Sort options
        ├── dialogs/
        │   ├── confirm_dialog.lustre  # Confirmation modal
        │   ├── task_dialog.lustre     # Add/edit task modal
        │   └── export_dialog.lustre   # Export options
        └── common/
            ├── button.lustre          # Button variants
            ├── badge.lustre           # Status/priority badges
            ├── empty_state.lustre     # Empty content placeholder
            ├── toast.lustre           # Notification toast
            └── loading.lustre         # Loading spinner
```

## Component Specifications

### Layout Components

#### app_shell.lustre - Responsive layout wrapper
```html
@params(
  sidebar_open: Bool,
  on_toggle_sidebar: fn() -> msg,
  current_view: View,
)

<div class="min-h-screen bg-gray-50">
  <!-- Sidebar - hidden on mobile, slide-in drawer -->
  <aside class="fixed inset-y-0 left-0 z-40 w-64 transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-auto"
    {#if sidebar_open}
      <!-- Mobile overlay -->
      <div class="fixed inset-0 bg-black bg-opacity-50 lg:hidden" @click={on_toggle_sidebar()}></div>
    {/if}
  >
    <sidebar ... />
  </aside>

  <!-- Main content area -->
  <main class="lg:ml-64 min-h-screen">
    <header ... />
    <div class="p-4 lg:p-6">
      <!-- Content slot -->
    </div>
  </main>

  <!-- Mobile bottom navigation -->
  <mobile_nav class="lg:hidden fixed bottom-0 left-0 right-0" ... />
</div>
```

#### sidebar.lustre - Navigation with projects
```html
@import(app/model.{type Project})

@params(
  projects: List(Project),
  current_project: Option(String),
  on_select_project: fn(Option(String)) -> msg,
  on_create_project: fn() -> msg,
)

<nav class="h-full bg-white border-r border-gray-200 flex flex-col">
  <div class="p-4 border-b border-gray-200">
    <h1 class="text-xl font-bold text-gray-900">Task Manager</h1>
  </div>

  <div class="flex-1 overflow-y-auto py-4">
    <!-- Quick filters -->
    <div class="px-4 mb-4">
      <h2 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Quick Filters</h2>
      <ul class="space-y-1">
        <li>
          <button class="w-full flex items-center px-3 py-2 text-sm rounded-md hover:bg-gray-100"
            @click={on_select_project(None)}>
            <span class="mr-3">📥</span> All Tasks
          </button>
        </li>
        <li>
          <button class="w-full flex items-center px-3 py-2 text-sm rounded-md hover:bg-gray-100">
            <span class="mr-3">📅</span> Today
          </button>
        </li>
        <li>
          <button class="w-full flex items-center px-3 py-2 text-sm rounded-md hover:bg-gray-100">
            <span class="mr-3">⏰</span> Overdue
          </button>
        </li>
      </ul>
    </div>

    <!-- Projects -->
    <div class="px-4">
      <div class="flex items-center justify-between mb-2">
        <h2 class="text-xs font-semibold text-gray-500 uppercase tracking-wider">Projects</h2>
        <button class="text-gray-400 hover:text-gray-600" @click={on_create_project()}>
          <span>+</span>
        </button>
      </div>
      <ul class="space-y-1">
        {#each projects as project, _}
          <li>
            <button
              class="w-full flex items-center px-3 py-2 text-sm rounded-md"
              @click={on_select_project(Some(project.id))}
            >
              {#if current_project == Some(project.id)}
                <span class="font-medium text-blue-600">{project.name}</span>
              {:else}
                <span class="text-gray-700 hover:bg-gray-100">{project.name}</span>
              {/if}
              <span class="ml-auto text-xs text-gray-400">{int.to_string(project.task_count)}</span>
            </button>
          </li>
        {/each}
      </ul>
    </div>
  </div>

  <!-- User section -->
  <div class="p-4 border-t border-gray-200">
    <sl-dropdown placement="top-start">
      <button slot="trigger" class="flex items-center gap-2 text-sm text-gray-700">
        <span>Settings</span>
      </button>
      <sl-menu>
        <sl-menu-item>Export Tasks</sl-menu-item>
        <sl-menu-item>Import Tasks</sl-menu-item>
        <sl-divider></sl-divider>
        <sl-menu-item>Clear All Data</sl-menu-item>
      </sl-menu>
    </sl-dropdown>
  </div>
</nav>
```

#### mobile_nav.lustre - Bottom navigation for mobile
```html
@import(app/model.{type View, ListView, KanbanView})

@params(
  current_view: View,
  on_view_change: fn(View) -> msg,
  on_add_task: fn() -> msg,
)

<nav class="bg-white border-t border-gray-200 px-4 py-2 safe-area-pb">
  <div class="flex items-center justify-around">
    <button class="flex flex-col items-center py-2 px-4" @click={on_view_change(ListView)}>
      {#if current_view == ListView}
        <span class="text-blue-600 text-2xl">📋</span>
        <span class="text-xs text-blue-600 font-medium">List</span>
      {:else}
        <span class="text-gray-400 text-2xl">📋</span>
        <span class="text-xs text-gray-400">List</span>
      {/if}
    </button>

    <button
      class="flex items-center justify-center w-14 h-14 -mt-6 bg-blue-600 rounded-full shadow-lg text-white text-2xl"
      @click={on_add_task()}
    >
      +
    </button>

    <button class="flex flex-col items-center py-2 px-4" @click={on_view_change(KanbanView)}>
      {#if current_view == KanbanView}
        <span class="text-blue-600 text-2xl">📊</span>
        <span class="text-xs text-blue-600 font-medium">Board</span>
      {:else}
        <span class="text-gray-400 text-2xl">📊</span>
        <span class="text-xs text-gray-400">Board</span>
      {/if}
    </button>
  </div>
</nav>
```

### Task Components

#### task_card.lustre - Comprehensive task card
```html
@import(gleam/option.{type Option, Some, None})
@import(app/model.{type Task, type TaskStatus, type Priority, Todo, InProgress, Done, High, Medium, Low, NoPriority})

@params(
  task: Task,
  is_selected: Bool,
  on_toggle_status: fn() -> msg,
  on_click: fn() -> msg,
  on_drag_start: fn() -> msg,
)

<article
  class="group bg-white rounded-lg border border-gray-200 p-4 hover:shadow-md transition-shadow cursor-pointer"
  draggable="true"
  @click={on_click()}
  @dragstart={on_drag_start()}
>
  <div class="flex items-start gap-3">
    <!-- Checkbox -->
    <button
      class="mt-0.5 flex-shrink-0"
      @click={on_toggle_status()}
    >
      {#case task.status}
        {:Done}
          <span class="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center text-white text-xs">✓</span>
        {:InProgress}
          <span class="w-5 h-5 rounded-full border-2 border-blue-500 flex items-center justify-center">
            <span class="w-2 h-2 rounded-full bg-blue-500"></span>
          </span>
        {:Todo}
          <span class="w-5 h-5 rounded-full border-2 border-gray-300 group-hover:border-gray-400"></span>
      {/case}
    </button>

    <!-- Content -->
    <div class="flex-1 min-w-0">
      <h3 class="font-medium text-gray-900 truncate">
        {#if task.status == Done}
          <span class="line-through text-gray-500">{task.title}</span>
        {:else}
          {task.title}
        {/if}
      </h3>

      {#if task.description != ""}
        <p class="mt-1 text-sm text-gray-500 line-clamp-2">{task.description}</p>
      {/if}

      <div class="mt-2 flex items-center gap-2 flex-wrap">
        <!-- Priority badge -->
        {#case task.priority}
          {:High}
            <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800">
              High
            </span>
          {:Medium}
            <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-yellow-100 text-yellow-800">
              Medium
            </span>
          {:Low}
            <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
              Low
            </span>
          {:NoPriority}
            <!-- No badge for no priority -->
        {/case}

        <!-- Due date -->
        {#case task.due_date}
          {:Some(date)}
            {#if is_overdue(date)}
              <span class="inline-flex items-center text-xs text-red-600">
                ⏰ Overdue
              </span>
            {:else}
              <span class="inline-flex items-center text-xs text-gray-500">
                📅 {format_date(date)}
              </span>
            {/if}
          {:None}
            <!-- No due date -->
        {/case}

        <!-- Subtask progress -->
        {#if list.length(task.subtasks) > 0}
          <span class="inline-flex items-center text-xs text-gray-500">
            ☑ {int.to_string(completed_subtasks(task))}/{int.to_string(list.length(task.subtasks))}
          </span>
        {/if}
      </div>
    </div>
  </div>
</article>
```

#### kanban_board.lustre - Kanban view with drag-drop
```html
@import(app/model.{type Task, type TaskStatus, Todo, InProgress, Done})

@params(
  todo_tasks: List(Task),
  in_progress_tasks: List(Task),
  done_tasks: List(Task),
  on_task_click: fn(String) -> msg,
  on_drop: fn(String, TaskStatus) -> msg,
)

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 lg:gap-6">
  <!-- Todo Column -->
  <div
    class="bg-gray-100 rounded-lg p-4"
    @dragover={prevent_default()}
    @drop={on_drop(get_dragged_id(), Todo)}
  >
    <h2 class="font-semibold text-gray-700 mb-4 flex items-center gap-2">
      <span class="w-3 h-3 rounded-full bg-gray-400"></span>
      Todo
      <span class="ml-auto text-sm font-normal text-gray-500">{int.to_string(list.length(todo_tasks))}</span>
    </h2>
    <div class="space-y-3">
      {#each todo_tasks as task, _}
        <task_card task={task} on_click={fn() { on_task_click(task.id) }} ... />
      {/each}
    </div>
  </div>

  <!-- In Progress Column -->
  <div
    class="bg-blue-50 rounded-lg p-4"
    @dragover={prevent_default()}
    @drop={on_drop(get_dragged_id(), InProgress)}
  >
    <h2 class="font-semibold text-gray-700 mb-4 flex items-center gap-2">
      <span class="w-3 h-3 rounded-full bg-blue-500"></span>
      In Progress
      <span class="ml-auto text-sm font-normal text-gray-500">{int.to_string(list.length(in_progress_tasks))}</span>
    </h2>
    <div class="space-y-3">
      {#each in_progress_tasks as task, _}
        <task_card task={task} on_click={fn() { on_task_click(task.id) }} ... />
      {/each}
    </div>
  </div>

  <!-- Done Column -->
  <div
    class="bg-green-50 rounded-lg p-4"
    @dragover={prevent_default()}
    @drop={on_drop(get_dragged_id(), Done)}
  >
    <h2 class="font-semibold text-gray-700 mb-4 flex items-center gap-2">
      <span class="w-3 h-3 rounded-full bg-green-500"></span>
      Done
      <span class="ml-auto text-sm font-normal text-gray-500">{int.to_string(list.length(done_tasks))}</span>
    </h2>
    <div class="space-y-3">
      {#each done_tasks as task, _}
        <task_card task={task} on_click={fn() { on_task_click(task.id) }} ... />
      {/each}
    </div>
  </div>
</div>
```

#### task_form.lustre - Complete task editing form
```html
@import(gleam/option.{type Option, Some, None})
@import(app/model.{type Task, type Priority, High, Medium, Low, NoPriority})

@params(
  task: Option(Task),
  title: String,
  description: String,
  priority: Priority,
  due_date: Option(String),
  project_id: Option(String),
  on_title_change: fn(String) -> msg,
  on_description_change: fn(String) -> msg,
  on_priority_change: fn(Priority) -> msg,
  on_due_date_change: fn(Option(String)) -> msg,
  on_submit: fn() -> msg,
  on_cancel: fn() -> msg,
)

<form class="space-y-6" @submit={on_submit()}>
  <!-- Title -->
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
    <sl-input
      value={title}
      placeholder="What needs to be done?"
      @sl-input={on_title_change}
      required
    />
  </div>

  <!-- Description -->
  <div>
    <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
    <sl-textarea
      value={description}
      placeholder="Add more details..."
      rows="3"
      @sl-input={on_description_change}
    />
  </div>

  <!-- Priority and Due Date - responsive grid -->
  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">Priority</label>
      <sl-select value={priority_to_string(priority)} @sl-change={on_priority_change}>
        <sl-option value="none">No Priority</sl-option>
        <sl-option value="low">Low</sl-option>
        <sl-option value="medium">Medium</sl-option>
        <sl-option value="high">High</sl-option>
      </sl-select>
    </div>

    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">Due Date</label>
      <sl-input
        type="date"
        value={option.unwrap(due_date, "")}
        @sl-input={on_due_date_change}
      />
    </div>
  </div>

  <!-- Actions -->
  <div class="flex flex-col-reverse sm:flex-row sm:justify-end gap-3 pt-4 border-t border-gray-200">
    <sl-button variant="default" @click={on_cancel()}>Cancel</sl-button>
    <sl-button variant="primary" type="submit">
      {#case task}
        {:Some(_)}
          Save Changes
        {:None}
          Create Task
      {/case}
    </sl-button>
  </div>
</form>
```

### Common Components

#### toast.lustre - Notification component
```html
@import(app/model.{type ToastType, Success, Error, Info, Warning})

@params(
  message: String,
  toast_type: ToastType,
  is_visible: Bool,
  on_dismiss: fn() -> msg,
)

{#if is_visible}
  <div class="fixed bottom-4 right-4 z-50 animate-slide-up">
    <div class="flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg">
      {#case toast_type}
        {:Success}
          <div class="bg-green-100 text-green-800 rounded-lg px-4 py-3 flex items-center gap-3">
            <span>✓</span>
            <span>{message}</span>
            <button class="ml-4 text-green-600 hover:text-green-800" @click={on_dismiss()}>×</button>
          </div>
        {:Error}
          <div class="bg-red-100 text-red-800 rounded-lg px-4 py-3 flex items-center gap-3">
            <span>✕</span>
            <span>{message}</span>
            <button class="ml-4 text-red-600 hover:text-red-800" @click={on_dismiss()}>×</button>
          </div>
        {:Warning}
          <div class="bg-yellow-100 text-yellow-800 rounded-lg px-4 py-3 flex items-center gap-3">
            <span>⚠</span>
            <span>{message}</span>
            <button class="ml-4 text-yellow-600 hover:text-yellow-800" @click={on_dismiss()}>×</button>
          </div>
        {:Info}
          <div class="bg-blue-100 text-blue-800 rounded-lg px-4 py-3 flex items-center gap-3">
            <span>ℹ</span>
            <span>{message}</span>
            <button class="ml-4 text-blue-600 hover:text-blue-800" @click={on_dismiss()}>×</button>
          </div>
      {/case}
    </div>
  </div>
{/if}
```

#### empty_state.lustre - Empty content placeholder
```html
@params(
  icon: String,
  title: String,
  description: String,
  action_label: String,
  on_action: fn() -> msg,
)

<div class="flex flex-col items-center justify-center py-12 px-4 text-center">
  <div class="text-6xl mb-4">{icon}</div>
  <h3 class="text-lg font-medium text-gray-900 mb-2">{title}</h3>
  <p class="text-gray-500 mb-6 max-w-sm">{description}</p>
  <sl-button variant="primary" @click={on_action()}>
    {action_label}
  </sl-button>
</div>
```

## Types Module

```gleam
// src/model.gleam

import gleam/option.{type Option}

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

pub type Subtask {
  Subtask(id: String, text: String, completed: Bool)
}

pub type TaskStatus {
  Todo
  InProgress
  Done
}

pub type Priority {
  High
  Medium
  Low
  NoPriority
}

pub type Project {
  Project(id: String, name: String, color: String, task_count: Int)
}

pub type View {
  ListView
  KanbanView
}

pub type Filter {
  All
  ByProject(String)
  Today
  Overdue
}

pub type SortBy {
  SortByCreated
  SortByDueDate
  SortByPriority
  SortByTitle
}

pub type ToastType {
  Success
  Error
  Warning
  Info
}

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
  )
}

pub type DialogState {
  NoDialog
  AddTaskDialog
  EditTaskDialog(String)
  DeleteConfirmDialog(String)
  ExportDialog
}

pub type FormState {
  FormState(
    title: String,
    description: String,
    priority: Priority,
    due_date: Option(String),
    project_id: Option(String),
  )
}
```

## Responsive Breakpoints

```
Mobile:    < 640px   - Single column, bottom nav, slide-out sidebar
Tablet:    640-1023px - Two columns, collapsible sidebar
Desktop:   >= 1024px  - Full layout with permanent sidebar
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `n` | New task |
| `Escape` | Close dialog/deselect |
| `1-3` | Set priority (in task view) |
| `/` | Focus search |
| `?` | Show keyboard shortcuts |

## Verification Checklist

- [ ] Responsive layout works on mobile, tablet, desktop
- [ ] Sidebar collapses on mobile with hamburger menu
- [ ] Bottom navigation shows on mobile only
- [ ] Kanban board scrolls horizontally on mobile
- [ ] Task cards are touch-friendly
- [ ] Dialogs are mobile-friendly
- [ ] All CRUD operations work
- [ ] Filters and search work
- [ ] LocalStorage persistence works
- [ ] Export/Import works
- [ ] Toast notifications appear and dismiss
- [ ] Empty states show appropriate messages
- [ ] Loading states display correctly
- [ ] Keyboard navigation works
- [ ] README comprehensively documents all features

## Files to Create

### Configuration
- `examples/08_complete/gleam.toml`
- `examples/08_complete/README.md`
- `examples/08_complete/assets/styles.css`

### Core Modules
- `examples/08_complete/src/app.gleam`
- `examples/08_complete/src/model.gleam`
- `examples/08_complete/src/msg.gleam`
- `examples/08_complete/src/update.gleam`
- `examples/08_complete/src/storage.gleam`

### Layout Components
- `examples/08_complete/src/components/layout/app_shell.lustre`
- `examples/08_complete/src/components/layout/sidebar.lustre`
- `examples/08_complete/src/components/layout/header.lustre`
- `examples/08_complete/src/components/layout/mobile_nav.lustre`

### Task Components
- `examples/08_complete/src/components/tasks/task_card.lustre`
- `examples/08_complete/src/components/tasks/task_list.lustre`
- `examples/08_complete/src/components/tasks/task_detail.lustre`
- `examples/08_complete/src/components/tasks/task_form.lustre`
- `examples/08_complete/src/components/tasks/subtask_item.lustre`
- `examples/08_complete/src/components/tasks/kanban_board.lustre`

### Filter Components
- `examples/08_complete/src/components/filters/filter_bar.lustre`
- `examples/08_complete/src/components/filters/search_input.lustre`
- `examples/08_complete/src/components/filters/sort_dropdown.lustre`

### Dialog Components
- `examples/08_complete/src/components/dialogs/confirm_dialog.lustre`
- `examples/08_complete/src/components/dialogs/task_dialog.lustre`
- `examples/08_complete/src/components/dialogs/export_dialog.lustre`

### Common Components
- `examples/08_complete/src/components/common/button.lustre`
- `examples/08_complete/src/components/common/badge.lustre`
- `examples/08_complete/src/components/common/empty_state.lustre`
- `examples/08_complete/src/components/common/toast.lustre`
- `examples/08_complete/src/components/common/loading.lustre`

# Task Manager - Drag and Drop

Extends the complete task manager example with HTML5 Drag and Drop API support for moving tasks between kanban board columns.

## Drag and Drop Features

- Drag task cards between Todo, In Progress, and Done columns
- Visual drop zone feedback with highlighted borders when dragging over columns
- Smooth transitions between highlighted and normal states
- Automatic task status update on drop
- Works in both light and dark mode

## All Features

### Core Functionality
- Create, read, update, delete tasks
- Task categories/projects
- Priority levels (High, Medium, Low, None)
- Due dates with overdue indicators
- Task status workflow (Todo -> In Progress -> Done)
- Subtasks/checklist items
- Search and filter
- Bulk actions (complete all, delete completed)

### UI/UX
- Responsive sidebar navigation (collapsible on mobile)
- Kanban board view with drag and drop
- List view with sorting
- Empty states with helpful prompts
- Confirmation dialogs for destructive actions
- Toast notifications for feedback

## Template Features Demonstrated

This example showcases all Lustre template features:

### Control Flow
- `{#if}...{:else}...{/if}` - Conditional rendering for selected states, empty states
- `{#each}...{/each}` - Iterating over tasks, projects, subtasks
- `{#case}...{/case}` - Pattern matching on task status, priority, toast type

### Attributes
- Static attributes: `class="..."`
- Dynamic attributes: `value={form.title}`
- Boolean attributes: `checked`, `open`, `required`
- Event handlers: `@click`, `@sl-input`, `@sl-change`

### Web Components (Shoelace)
- `sl-input`, `sl-textarea` - Form inputs
- `sl-button` - Styled buttons
- `sl-select`, `sl-option` - Dropdowns
- `sl-dialog` - Modal dialogs
- `sl-dropdown`, `sl-menu` - Menus
- `sl-spinner` - Loading indicator

### Styling (Tailwind CSS)
- Responsive design with breakpoint modifiers (`sm:`, `md:`, `lg:`)
- Utility classes for layout, spacing, colors
- State variants (`hover:`, `focus:`)
- Custom animations

## Architecture

```
09_drag_drop/
├── gleam.toml              # Project configuration
├── README.md               # This file
├── assets/
│   └── styles.css          # Custom styles
└── src/
    ├── app.gleam           # Main entry point
    ├── model.gleam         # Application state types
    ├── msg.gleam           # Message types
    ├── update.gleam        # State update logic
    ├── storage.gleam       # LocalStorage persistence
    ├── ffi.mjs             # JavaScript FFI
    └── components/
        ├── layout/         # Layout components
        ├── tasks/          # Task-related components
        ├── filters/        # Filter components
        ├── dialogs/        # Dialog components
        └── common/         # Shared components
```

## Running the Example

1. Generate Gleam files from templates:
   ```bash
   just run examples/09_drag_drop
   ```

2. Install dependencies:
   ```bash
   cd examples/09_drag_drop
   gleam deps download
   ```

3. Start the development server:
   ```bash
   gleam run -m lustre/dev start
   ```

4. Open http://localhost:1234 in your browser

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `n` | New task |
| `Escape` | Close dialog/deselect |
| `/` | Focus search |

## Responsive Breakpoints

- **Mobile** (< 640px): Single column, bottom nav, slide-out sidebar
- **Tablet** (640-1023px): Two columns, collapsible sidebar
- **Desktop** (>= 1024px): Full layout with permanent sidebar

## Component Breakdown

### Layout Components
- `sidebar.ghtml` - Navigation sidebar with projects
- `header.ghtml` - Top header with search and controls
- `mobile_nav.ghtml` - Bottom navigation for mobile

### Task Components
- `task_list.ghtml` - List of tasks with inline card rendering
- `task_detail.ghtml` - Full task view with subtask management
- `kanban_board.ghtml` - Kanban board view

### Filter Components
- `filter_bar.ghtml` - Filter and sort controls

### Dialog Components
- `confirm_dialog.ghtml` - Confirmation modal
- `export_dialog.ghtml` - Export/import options

### Common Components
- `empty_state.ghtml` - Empty content placeholder
- `toast.ghtml` - Notification toast

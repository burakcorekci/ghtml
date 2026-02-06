# Task Manager - Drag and Drop

Extends the complete task manager (example 08) with HTML5 drag and drop support for the kanban board view.

## Features

### New in This Example
- **Drag and Drop**: Drag task cards between kanban columns (Todo, In Progress, Done)
- **Drop Zone Highlighting**: Visual feedback when dragging over valid drop targets
- **Drag State Tracking**: Model tracks dragged task and target column

### Inherited from Example 08
- Create, read, update, delete tasks
- Task categories/projects with priority levels
- Due dates with overdue indicators
- Kanban board and list views
- Search, filter, and bulk actions
- LocalStorage persistence
- Responsive design with Shoelace + Tailwind CSS

## Template Features Demonstrated

### Drag and Drop Events
- `@dragstart` - Capture which task is being dragged
- `@dragover` - Highlight drop zones, prevent default to allow drop
- `@dragleave` - Remove drop zone highlighting
- `@drop` - Move task to target column
- `@dragend` - Clean up drag state

### HTML5 Attributes
- `draggable="true"` - Make task cards draggable
- Dynamic classes for drop zone highlighting

## Architecture

```
09_drag_drop/
├── gleam.toml              # Project configuration
├── README.md               # This file
├── assets/
│   └── styles.css          # Custom styles
└── src/
    ├── app.gleam           # Main entry point
    ├── model.gleam         # Application state (+ drag state)
    ├── msg.gleam           # Message types (+ drag messages)
    ├── update.gleam        # State update logic (+ drag handlers)
    ├── storage.gleam       # LocalStorage persistence
    ├── ffi.mjs             # JavaScript FFI
    └── components/
        ├── layout/         # Layout components
        ├── tasks/          # Task components (kanban_board with drag/drop)
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

## Drag and Drop Usage

1. Switch to the **Kanban Board** view
2. **Drag** a task card from any column
3. **Hover** over a target column to see the drop zone highlight
4. **Drop** the task to move it to the new status

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `n` | New task |
| `Escape` | Close dialog/deselect |
| `/` | Focus search |

# Codebase Context

Read `CODEBASE.md` for architecture overview, module guide, and key patterns before implementing any task. Update `CODEBASE.md` after completing implementations that add new modules, change architecture, or introduce new patterns.

# Development Workflow

## Test Driven Development
1. Implement tests for the change that fail
2. Implement the simplest implementation that succeeds
3. Refactor to the least complex state:
   - Most maintainable and extendible
   - Uses idiomatic Gleam/Lustre patterns
   - Handles edge cases
   - Includes documentation comments

## Commands
See the Quick Reference table in `CODEBASE.md` for all commands. Key ones:
- `just check` - Run all quality checks before committing
- `just ci` - Simulate CI pipeline before pushing

# Epic-Based Work

The `.plan/` directory organizes multi-session work into epics with tasks.

## Directory Structure

```
.plan/
├── _template/                    # Templates for creating new epics
│   ├── PLAN.md                   # Epic plan template
│   └── tasks/
│       ├── README.md             # Tasks overview template
│       └── 000_template_task.md  # Individual task template
├── initial_implementation/       # Example completed epic
│   ├── PLAN.md                   # High-level epic plan
│   └── tasks/
│       ├── README.md             # Task overview and status
│       ├── 001_project_setup.md  # Individual task specs
│       └── ...
└── [next_epic]/                  # Future epics follow same structure
```

## Creating a New Epic

1. Run: `just epic your_epic_name`
2. Edit `.plan/your_epic_name/PLAN.md` with your epic's details
3. Create task files from `tasks/000_template_task.md`
4. Update `tasks/README.md` with task status tracking

## Executing Work

- **Single task**: See `SUBAGENT.md` for step-by-step execution
- **Full epic**: See `ORCHESTRATOR.md` for subagent-based execution

# Codebase Context

Read `.claude/CODEBASE.md` for architecture overview, module guide, and key patterns before implementing any task. Update `.claude/CODEBASE.md` after completing implementations that add new modules, change architecture, or introduce new patterns.

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
See the Quick Reference table in `.claude/CODEBASE.md` for all commands. Key ones:
- `just check` - Run all quality checks before committing
- `just ci` - Simulate CI pipeline before pushing

## GIF Recording

Regenerate README demos with `just gifs`. See `assets/gif-record/README.md` for prerequisites and details.

# Epic-Based Work

The `.claude/plan/` directory contains detailed specifications for multi-session work organized into epics with tasks.

## Directory Structure

```
.claude/plan/
├── _template/                    # Templates for creating new epics
│   ├── PLAN.md                   # Epic plan template
│   └── tasks/
│       ├── README.md             # Tasks overview template
│       └── 000_template_task.md  # Individual task template
├── <epic_name>/                  # Each epic has its own folder
│   ├── PLAN.md                   # High-level epic plan
│   └── tasks/
│       ├── README.md             # Task overview and status
│       └── NNN_task_name.md      # Individual task specs
```

## Creating a New Epic

1. Run: `just epic your_epic_name`
2. Edit `.claude/plan/your_epic_name/PLAN.md` with your epic's details
3. Create task files from `tasks/000_template_task.md`
4. Update `tasks/README.md` with task status tracking

# Execution Modes

Choose the appropriate mode based on your workflow:

## Manual Mode (Sequential)

For human-orchestrated, step-by-step task execution:
- Status tracked in `.claude/plan/<epic>/tasks/README.md` (markdown checkboxes)
- Single task at a time
- See: `.claude/SUBAGENT.md` for detailed instructions

```bash
# View task, implement, update README status manually
```

## Automated Mode (Parallel)

For script-orchestrated, parallel agent execution:
- Status tracked in Beads (machine-queryable)
- Multiple agents work concurrently
- See: `.claude/docs/orchestration.md` for setup and usage

```bash
# Initialize beads (first time)
bd init

# Run parallel orchestration
just orchestrate --epic <epic_id>
```

## When to Use Which

| Scenario | Mode |
|----------|------|
| Learning/exploring the codebase | Manual |
| Single focused task | Manual |
| Multiple independent tasks | Automated |
| Want PR review workflow | Automated |
| CI/CD integration | Automated |

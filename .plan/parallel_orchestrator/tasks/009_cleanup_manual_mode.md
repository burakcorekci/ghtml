# Task 009: Cleanup Manual Mode Instructions

## Description

Once Beads is fully adopted, consolidate all task management into Beads and remove redundant documentation. The `.plan/` folder structure becomes unnecessary when Beads holds task descriptions, dependencies, and status.

## Dependencies

- 008_migrate_existing_epics - Migration must be complete and validated

## Success Criteria

1. CLAUDE.md simplified to Beads-only workflow
2. SUBAGENT.md removed
3. `.plan/` folder archived or removed
4. New workflow uses Beads for everything
5. No broken documentation links

## Final State

### Before (Current)
```
.plan/
├── epic_name/
│   ├── PLAN.md              # Epic overview
│   └── tasks/
│       ├── README.md        # Status tracking (redundant with Beads)
│       └── 001_task.md      # Task spec (redundant with Beads description)

.beads/
└── issues.jsonl             # Also has task info
```

### After (Consolidated)
```
.beads/
└── issues.jsonl             # Single source of truth
    - Epic descriptions
    - Task descriptions
    - Dependencies
    - Status
    - Metadata (links to PRs, etc.)

docs/
└── orchestration.md         # How to use the system
```

**No more `.plan/` folder for active work.**

## Implementation Steps

### 1. Update CLAUDE.md

Simplify to Beads-only:

```markdown
# Codebase Context

Read `CODEBASE.md` for architecture overview and patterns.

# Development Workflow

## Test Driven Development
1. Write failing tests first
2. Implement simplest solution
3. Refactor to clean state

## Commands
- `just check` - Run all quality checks
- `just ci` - Simulate CI pipeline

# Task Management

All tasks are tracked in **Beads**.

## Quick Reference

```bash
bd ready              # Show tasks ready to work on
bd list               # Show all tasks
bd show <id>          # Show task details and description
bd dep tree           # Show dependency graph

just orchestrate      # Run parallel agents
just worker <id>      # Work on single task
```

## Creating Work

```bash
# Create epic with description
bd create "Epic: Feature Name" -p 0

# Create task with full description
bd create "Implement parser" -p 1 --parent <epic-id>

# Add detailed description
bd comment <task-id> "
## Requirements
- Parse X format
- Handle edge cases Y, Z

## Acceptance Criteria
- [ ] Unit tests pass
- [ ] Integration tests pass
"

# Set dependencies
bd dep add <task-id> <blocker-id>
```

## Documentation
- `CODEBASE.md` - Architecture and patterns
- `docs/orchestration.md` - Orchestration guide
```

### 2. Remove SUBAGENT.md

```bash
git rm SUBAGENT.md
```

### 3. Archive .plan/ Folder

Option A: Remove entirely
```bash
git rm -r .plan/
```

Option B: Archive to docs/archive/ for historical reference
```bash
mkdir -p docs/archive
git mv .plan/ docs/archive/plan-historical/
```

**Recommendation:** Option A - remove entirely. Git history preserves it if needed.

### 4. Update docs/orchestration.md

Remove references to `.plan/` task files. Update examples to show task details in Beads:

```markdown
## Creating Detailed Tasks

Task descriptions live in Beads, not separate files:

```bash
# Create task
bd create "Add user authentication" -p 1

# Add detailed requirements via comment
bd comment lt-a1b2 "
## Description
Implement JWT-based authentication for the API.

## Requirements
- Login endpoint returns JWT token
- Token expires after 24 hours
- Refresh token mechanism

## Test Cases
- Valid credentials return token
- Invalid credentials return 401
- Expired token returns 401

## Files to Modify
- src/auth/handler.gleam
- src/auth/jwt.gleam
- test/auth_test.gleam
"
```

View full task details:
```bash
bd show lt-a1b2
```
```

### 5. Update Justfile

Remove epic template command if it exists:
```bash
# Remove or update
# epic name:
#     cp -r .plan/_template .plan/{{name}}
```

Add Beads convenience commands:
```makefile
# Create new epic
new-epic name:
    bd create "Epic: {{name}}" -p 0

# Create task under epic
new-task epic subject:
    bd create "{{subject}}" -p 1 --parent {{epic}}
```

### 6. Update .gitignore

Remove .plan/ ignores if any, ensure .beads/ is tracked:
```gitignore
# Beads local cache (not the data)
.beads/*.db
.beads/*.db-*
```

## Test Cases

### Test 1: No .plan/ References
```bash
#!/bin/bash
if grep -r "\.plan/" CLAUDE.md docs/; then
    echo "FAIL: still references .plan/"
    exit 1
fi
echo "PASS: no .plan/ references"
```

### Test 2: SUBAGENT.md Removed
```bash
#!/bin/bash
if [ -f "SUBAGENT.md" ]; then
    echo "FAIL: SUBAGENT.md still exists"
    exit 1
fi
echo "PASS: SUBAGENT.md removed"
```

### Test 3: Beads Has Task Details
```bash
#!/bin/bash
# Verify tasks have descriptions
empty_desc=$(bd list --json | jq '[.issues[] | select(.description == "" or .description == null)] | length')
if [ "$empty_desc" -gt 0 ]; then
    echo "WARNING: $empty_desc tasks have no description"
fi
echo "PASS: checked task descriptions"
```

## Verification Checklist

- [ ] CLAUDE.md updated to Beads-only workflow
- [ ] SUBAGENT.md removed
- [ ] `.plan/` folder removed or archived
- [ ] docs/orchestration.md updated (no .plan/ references)
- [ ] Justfile updated with Beads commands
- [ ] All existing task details migrated to Beads descriptions
- [ ] No broken documentation links
- [ ] Team informed of workflow change

## Migration of Task Details

Before removing `.plan/`, ensure task details are in Beads:

```bash
# For each migrated task, add the spec content as a comment
for task in $(bd list --json | jq -r '.issues[] | select(.meta.spec_file != null) | "\(.id)|\(.meta.spec_file)"'); do
    id=$(echo "$task" | cut -d'|' -f1)
    spec=$(echo "$task" | cut -d'|' -f2)

    if [ -f "$spec" ]; then
        # Add spec content as comment
        bd comment "$id" "$(cat "$spec")"
        echo "Added spec to $id"
    fi
done
```

## Notes

- Git history preserves all `.plan/` content if needed for reference
- Beads comments support markdown, so task specs translate directly
- Consider using `bd comment` for detailed specs vs cramming into description
- The `.plan/_template/` patterns can become documented conventions in docs/orchestration.md

## Files to Modify

- `CLAUDE.md` - Simplify to Beads-only
- `SUBAGENT.md` - Remove
- `.plan/` - Remove entirely
- `docs/orchestration.md` - Update, remove .plan/ references
- `justfile` - Update commands
- `.gitignore` - Clean up

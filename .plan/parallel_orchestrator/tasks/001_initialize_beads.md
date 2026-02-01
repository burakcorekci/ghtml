# Task 001: Initialize Beads

## Description

Set up Beads in the project as the single source of truth for orchestration state. This includes installation verification, project initialization, and documenting the workflow conventions.

## Dependencies

- None - this is the first task.

## Success Criteria

1. `bd --version` returns a valid version (0.20.1+ for hash-based IDs)
2. `.beads/` directory exists and is git-tracked
3. `bd list` returns empty list (no errors)
4. `.gitignore` updated to exclude SQLite cache if needed
5. Beads workflow documented in project

## Implementation Steps

### 1. Verify Beads Installation

Check if beads CLI is available and meets minimum version requirement.

```bash
# Check installation
bd --version

# If not installed, install via:
# go install github.com/steveyegge/beads/cmd/bd@latest
# or
# brew install beads
```

### 2. Initialize Beads in Project

```bash
cd /Users/burakpersonal/projects/lustre_template_gen
bd init
```

This creates:
- `.beads/config.json` - Project configuration
- `.beads/issues.jsonl` - Issue database (append-only)

### 3. Configure Beads

Create or update `.beads/config.json`:

```json
{
  "project": "lustre_template_gen",
  "prefix": "lt",
  "default_priority": 2
}
```

### 4. Update .gitignore

Add SQLite cache exclusion if not already present:

```gitignore
# Beads local cache
.beads/*.db
.beads/*.db-*
```

### 5. Create Workflow Documentation

Add beads workflow to `CODEBASE.md` or create `.beads/WORKFLOW.md`:

```markdown
## Beads Workflow

### Task Lifecycle
1. Create: `bd create "Task subject" -p 1`
2. Start: `bd update <id> --status in_progress`
3. Complete: `bd close <id>`

### Orchestration Metadata
Tasks managed by orchestrator include metadata:
- `meta.worktree` - Path to git worktree
- `meta.branch` - Git branch name
- `meta.agent_pid` - Agent process ID
- `meta.pr_number` - GitHub PR number
- `meta.phase` - Current phase (spawned|working|committed|pr_created|merged)

### Querying
- Ready tasks: `bd ready`
- Active tasks: `bd list --status in_progress`
- Full state: `bd list --json`
```

## Test Cases

### Test 1: Beads CLI Available
```bash
#!/bin/bash
bd --version || { echo "FAIL: beads not installed"; exit 1; }
echo "PASS: beads installed"
```

### Test 2: Project Initialized
```bash
#!/bin/bash
[ -f ".beads/config.json" ] || { echo "FAIL: beads not initialized"; exit 1; }
echo "PASS: beads initialized"
```

### Test 3: Can Create and Query Tasks
```bash
#!/bin/bash
# Create test task
test_id=$(bd create "Test task" --json | jq -r '.id')

# Verify it appears in list
bd list --json | jq -e ".issues[] | select(.id == \"$test_id\")" || {
    echo "FAIL: task not found in list"
    exit 1
}

# Cleanup
bd delete "$test_id" --force

echo "PASS: create/query works"
```

## Verification Checklist

- [ ] `bd --version` shows 0.20.1 or higher
- [ ] `bd init` completed without errors
- [ ] `.beads/` directory exists
- [ ] `.beads/config.json` has correct project settings
- [ ] `.gitignore` excludes SQLite cache
- [ ] `bd list` works without errors
- [ ] Test task can be created and deleted
- [ ] Workflow documentation added

## Notes

- Hash-based IDs (e.g., `lt-a1b2`) require Beads 0.20.1+
- The SQLite cache (`.beads/*.db`) is for local performance only and should not be committed
- Consider running `bd init --stealth` for contributor mode if not project maintainer

## Files to Modify

- `.beads/config.json` - Create with project settings
- `.gitignore` - Add beads cache exclusions
- `CODEBASE.md` - Add beads workflow section (or create `.beads/WORKFLOW.md`)

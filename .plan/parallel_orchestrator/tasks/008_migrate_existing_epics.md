# Task 008: Migrate Existing Epics to Beads

## Description

Migrate all incomplete tasks from existing `.plan/` epics into Beads. This preserves the detailed specs in `.plan/` while enabling machine-queryable task tracking and parallel orchestration.

## Dependencies

- 007_documentation - System must be documented before migration

## Success Criteria

1. Migration script created and tested
2. All incomplete tasks from `.plan/` epics exist in Beads
3. Beads tasks link to `.plan/` spec files via metadata
4. Dependencies between tasks preserved
5. Epic hierarchy preserved (parent/child relationships)
6. No duplicate tasks created (idempotent migration)
7. Migration report generated

## Implementation Steps

### 1. Audit Existing Epics

First, identify all epics and their task status:

```bash
# List all epics
ls -d .plan/*/

# Expected epics:
# - .plan/initial_implementation/
# - .plan/learning_examples/
# - .plan/editor_support/
# - .plan/e2e_testing/
# - .plan/parallel_orchestrator/  (this epic)
```

### 2. Create Migration Script

Create `scripts/migrate-plan-to-beads.sh`:

```bash
#!/bin/bash
# ==============================================================================
# migrate-plan-to-beads.sh - Migrate .plan/ epics to Beads
#
# Usage: ./migrate-plan-to-beads.sh [--dry-run] [--epic NAME]
#
# Options:
#   --dry-run       Show what would be migrated without making changes
#   --epic NAME     Only migrate specific epic (folder name)
#
# Description:
#   Scans .plan/ directory for incomplete tasks and creates corresponding
#   Beads issues with links back to the spec files.
# ==============================================================================
set -euo pipefail

PLAN_DIR=".plan"
DRY_RUN=false
EPIC_FILTER=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --epic) EPIC_FILTER="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

log() { echo "[MIGRATE] $*"; }
dry() { $DRY_RUN && echo "[DRY-RUN] $*" || return 1; }

# Track created issues for report
declare -A CREATED_EPICS
declare -A CREATED_TASKS
declare -a SKIPPED_TASKS

# Parse task status from README.md
# Returns: pending, in_progress, complete, blocked
parse_task_status() {
    local readme="$1"
    local task_num="$2"

    if [ ! -f "$readme" ]; then
        echo "pending"
        return
    fi

    # Look for status in table: | 001 | Task Name | [x] Complete |
    local line=$(grep -E "^\| *${task_num} *\|" "$readme" 2>/dev/null || echo "")

    if echo "$line" | grep -q "\[x\]"; then
        echo "complete"
    elif echo "$line" | grep -q "\[~\]"; then
        echo "in_progress"
    elif echo "$line" | grep -q "\[!\]"; then
        echo "blocked"
    else
        echo "pending"
    fi
}

# Parse dependencies from task file
parse_dependencies() {
    local task_file="$1"

    if [ ! -f "$task_file" ]; then
        return
    fi

    # Look for "## Dependencies" section and extract task numbers
    sed -n '/^## Dependencies/,/^## /p' "$task_file" | \
        grep -oE '[0-9]{3}' | sort -u
}

# Get task subject from file
parse_task_subject() {
    local task_file="$1"

    # Extract from "# Task NNN: Subject" header
    head -5 "$task_file" | grep -E "^# Task" | sed 's/^# Task [0-9]*: *//' || \
        basename "$task_file" .md | sed 's/^[0-9]*_//' | tr '_' ' '
}

# Migrate a single epic
migrate_epic() {
    local epic_dir="$1"
    local epic_name=$(basename "$epic_dir")

    log "Processing epic: $epic_name"

    # Skip template
    if [ "$epic_name" = "_template" ]; then
        log "  Skipping template"
        return
    fi

    # Check for PLAN.md
    local plan_file="${epic_dir}/PLAN.md"
    if [ ! -f "$plan_file" ]; then
        log "  Warning: No PLAN.md found"
        return
    fi

    # Extract epic title from PLAN.md
    local epic_title=$(head -5 "$plan_file" | grep -E "^# Epic:" | sed 's/^# Epic: *//' || echo "$epic_name")

    # Check if epic already exists in beads (by searching for matching title)
    local existing_epic=$(bd list --json 2>/dev/null | \
        jq -r --arg title "$epic_title" \
        '.issues[] | select(.subject == $title and (.id | contains(".") | not)) | .id' | head -1)

    local epic_id=""
    if [ -n "$existing_epic" ]; then
        log "  Epic already exists: $existing_epic"
        epic_id="$existing_epic"
    else
        if dry "Would create epic: $epic_title"; then
            :
        else
            log "  Creating epic: $epic_title"
            epic_id=$(bd create "$epic_title" -p 0 \
                --meta plan_file="$plan_file" \
                --meta epic_name="$epic_name" \
                --json | jq -r '.id')
            log "  Created: $epic_id"
            CREATED_EPICS["$epic_name"]="$epic_id"
        fi
    fi

    # Process tasks
    local tasks_dir="${epic_dir}/tasks"
    local readme="${tasks_dir}/README.md"

    if [ ! -d "$tasks_dir" ]; then
        log "  No tasks directory"
        return
    fi

    # Map of task number -> beads ID for dependency resolution
    declare -A TASK_MAP

    # First pass: create all tasks
    for task_file in "$tasks_dir"/[0-9][0-9][0-9]_*.md; do
        [ -f "$task_file" ] || continue

        local task_basename=$(basename "$task_file")
        local task_num=${task_basename:0:3}
        local task_subject=$(parse_task_subject "$task_file")
        local task_status=$(parse_task_status "$readme" "$task_num")

        # Skip completed tasks
        if [ "$task_status" = "complete" ]; then
            log "    [$task_num] $task_subject - SKIPPED (complete)"
            SKIPPED_TASKS+=("$epic_name/$task_num: $task_subject (complete)")
            continue
        fi

        # Check if task already exists
        local existing_task=$(bd list --json 2>/dev/null | \
            jq -r --arg subj "$task_subject" \
            '.issues[] | select(.subject == $subj) | .id' | head -1)

        if [ -n "$existing_task" ]; then
            log "    [$task_num] $task_subject - EXISTS ($existing_task)"
            TASK_MAP["$task_num"]="$existing_task"
            continue
        fi

        # Determine priority based on status
        local priority=2
        [ "$task_status" = "in_progress" ] && priority=1
        [ "$task_status" = "blocked" ] && priority=3

        if dry "Would create task: [$task_num] $task_subject"; then
            TASK_MAP["$task_num"]="dry-run-$task_num"
        else
            log "    [$task_num] Creating: $task_subject"
            local task_id=$(bd create "$task_subject" -p "$priority" \
                --meta spec_file="$task_file" \
                --meta epic_name="$epic_name" \
                --meta task_num="$task_num" \
                --meta original_status="$task_status" \
                --json | jq -r '.id')

            TASK_MAP["$task_num"]="$task_id"
            CREATED_TASKS["$epic_name/$task_num"]="$task_id"

            # Link to epic
            if [ -n "$epic_id" ]; then
                bd dep add "$task_id" "$epic_id" --type parent 2>/dev/null || true
            fi

            # Set in_progress if it was in progress
            if [ "$task_status" = "in_progress" ]; then
                bd update "$task_id" --status in_progress
            fi
        fi
    done

    # Second pass: set up dependencies between tasks
    for task_file in "$tasks_dir"/[0-9][0-9][0-9]_*.md; do
        [ -f "$task_file" ] || continue

        local task_basename=$(basename "$task_file")
        local task_num=${task_basename:0:3}
        local task_id="${TASK_MAP[$task_num]:-}"

        [ -z "$task_id" ] && continue
        [[ "$task_id" == dry-run-* ]] && continue

        local deps=$(parse_dependencies "$task_file")
        for dep_num in $deps; do
            local dep_id="${TASK_MAP[$dep_num]:-}"
            if [ -n "$dep_id" ] && [[ "$dep_id" != dry-run-* ]]; then
                if ! dry "Would add dependency: $task_id blocked by $dep_id"; then
                    bd dep add "$task_id" "$dep_id" --type blocks 2>/dev/null || true
                    log "    Added dependency: $task_num -> $dep_num"
                fi
            fi
        done
    done
}

# Generate migration report
generate_report() {
    echo ""
    echo "=============================================="
    echo "Migration Report"
    echo "=============================================="
    echo ""
    echo "Epics created: ${#CREATED_EPICS[@]}"
    for epic in "${!CREATED_EPICS[@]}"; do
        echo "  - $epic -> ${CREATED_EPICS[$epic]}"
    done
    echo ""
    echo "Tasks created: ${#CREATED_TASKS[@]}"
    for task in "${!CREATED_TASKS[@]}"; do
        echo "  - $task -> ${CREATED_TASKS[$task]}"
    done
    echo ""
    echo "Tasks skipped (already complete): ${#SKIPPED_TASKS[@]}"
    for task in "${SKIPPED_TASKS[@]}"; do
        echo "  - $task"
    done
    echo ""
    echo "=============================================="
}

# Main
main() {
    log "Starting migration from .plan/ to Beads"

    # Verify beads is initialized
    bd list > /dev/null 2>&1 || { echo "Error: Beads not initialized. Run 'bd init' first."; exit 1; }

    $DRY_RUN && log "DRY RUN MODE - no changes will be made"

    # Process epics
    for epic_dir in "$PLAN_DIR"/*/; do
        [ -d "$epic_dir" ] || continue

        local epic_name=$(basename "$epic_dir")

        # Filter if specified
        if [ -n "$EPIC_FILTER" ] && [ "$epic_name" != "$EPIC_FILTER" ]; then
            continue
        fi

        migrate_epic "$epic_dir"
    done

    generate_report

    log "Migration complete!"
}

main "$@"
```

### 3. Make Script Executable

```bash
chmod +x scripts/migrate-plan-to-beads.sh
```

### 4. Add to Justfile

```makefile
# Migrate .plan/ epics to beads
migrate-to-beads *args:
    ./scripts/migrate-plan-to-beads.sh {{args}}

# Preview migration without making changes
migrate-to-beads-preview:
    ./scripts/migrate-plan-to-beads.sh --dry-run
```

### 5. Run Migration

```bash
# Preview first
just migrate-to-beads-preview

# Run actual migration
just migrate-to-beads

# Or migrate specific epic
just migrate-to-beads --epic learning_examples
```

### 6. Verify Migration

```bash
# Check epics created
bd list --json | jq '.issues[] | select(.id | contains(".") | not)'

# Check tasks with spec file links
bd list --json | jq '.issues[] | select(.meta.spec_file != null) | {id, subject, spec: .meta.spec_file}'

# View dependency tree
bd dep tree
```

## Test Cases

### Test 1: Dry Run Produces No Changes
```bash
#!/bin/bash
before=$(bd list --json | jq '.issues | length')
./scripts/migrate-plan-to-beads.sh --dry-run
after=$(bd list --json | jq '.issues | length')
[ "$before" = "$after" ] || exit 1
echo "PASS: dry run made no changes"
```

### Test 2: Idempotent Migration
```bash
#!/bin/bash
# Run migration twice
./scripts/migrate-plan-to-beads.sh --epic learning_examples
count1=$(bd list --json | jq '.issues | length')

./scripts/migrate-plan-to-beads.sh --epic learning_examples
count2=$(bd list --json | jq '.issues | length')

[ "$count1" = "$count2" ] || exit 1
echo "PASS: migration is idempotent"
```

### Test 3: Completed Tasks Skipped
```bash
#!/bin/bash
# Verify no completed tasks were migrated
bd list --json | jq -e '.issues[] | select(.meta.original_status == "complete")' && exit 1
echo "PASS: completed tasks not migrated"
```

### Test 4: Spec Files Linked
```bash
#!/bin/bash
# Verify all migrated tasks have spec_file metadata
bd list --json | jq -e '.issues[] | select(.meta.spec_file == null and .meta.task_num != null)' && exit 1
echo "PASS: all tasks have spec file links"
```

## Verification Checklist

- [ ] Migration script created at `scripts/migrate-plan-to-beads.sh`
- [ ] `--dry-run` mode works correctly
- [ ] `--epic` filter works correctly
- [ ] Completed tasks are skipped
- [ ] In-progress tasks marked as in_progress in beads
- [ ] Dependencies between tasks preserved
- [ ] Epic-to-task parent relationships created
- [ ] `meta.spec_file` links to `.plan/` task files
- [ ] Migration is idempotent (safe to run multiple times)
- [ ] Migration report generated
- [ ] Justfile commands added

## Expected Migration

Based on current `.plan/` epics:

| Epic | Expected Tasks |
|------|----------------|
| initial_implementation | Likely all complete - skip |
| learning_examples | Check README for incomplete |
| editor_support | Check README for incomplete |
| e2e_testing | Check README for incomplete |
| parallel_orchestrator | All pending (this epic) |

## Post-Migration Workflow

After migration:

1. **View migrated tasks**: `bd list`
2. **Check ready tasks**: `bd ready`
3. **Run orchestrator**: `just orchestrate --epic <id>`
4. **Reference specs**: `bd show <id>` shows `meta.spec_file`

The `.plan/` files remain as detailed specs - Beads just tracks execution state.

## Notes

- The `.plan/` directory is NOT deleted - it remains as documentation
- Beads tasks link back via `meta.spec_file` for reference
- Workers can read the spec file for detailed instructions
- Consider adding a `just task-spec <id>` command to quickly view linked spec

## Files to Modify

- `scripts/migrate-plan-to-beads.sh` - Create migration script
- `justfile` - Add migration commands

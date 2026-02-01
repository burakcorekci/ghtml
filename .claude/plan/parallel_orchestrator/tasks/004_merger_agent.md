# Task 004: Merger Agent

## Description

Create the merger agent that reviews and merges PRs created by worker agents. The merger runs periodically (or on-demand) to process the PR queue, checking CI status, reviewing diffs, and merging approved PRs.

## Dependencies

- 001_initialize_beads - Beads must be set up first

## Success Criteria

1. Merger agent prompt defined in `.claude/agents/merger.md`
2. Agent checks CI status before merging
3. Agent verifies PR is mergeable (no conflicts)
4. Agent uses squash merge with branch deletion
5. Agent updates Beads on successful merge
6. Agent handles merge failures gracefully
7. Manual invocation script available

## Implementation Steps

### 1. Create Merger Agent Prompt

Create `.claude/agents/merger.md`:

```markdown
# Merger Agent

You are the merger agent responsible for reviewing and merging PRs created by worker agents.

## Overview

Worker agents create PRs for their completed tasks. Your job is to:
1. Find PRs ready for merge
2. Verify CI passes
3. Review the changes
4. Merge or request changes

## Workflow

### Step 1: List Agent PRs

Find all open PRs from worker agents:
```bash
gh pr list --json number,title,headRefName,state,mergeable,statusCheckRollup \
    --jq '.[] | select(.headRefName | startswith("agent/"))'
```

### Step 2: For Each PR

#### 2a. Check CI Status
```bash
gh pr checks <number>
```

Skip if checks are still running or failing.

#### 2b. Check Mergeability
```bash
gh pr view <number> --json mergeable -q .mergeable
```

If `CONFLICTING`, comment and skip:
```bash
gh pr comment <number> --body "This PR has merge conflicts. Please rebase:
\`\`\`bash
git fetch origin main
git rebase origin/main
git push --force-with-lease
\`\`\`"
```

#### 2c. Review Diff
```bash
gh pr diff <number>
```

Check for:
- [ ] Changes match task description
- [ ] No obvious bugs or security issues
- [ ] Tests included
- [ ] No unrelated changes

#### 2d. Merge Decision

| CI | Conflicts | Review | Action |
|----|-----------|--------|--------|
| Pass | None | OK | Merge |
| Pass | None | Issues | Request changes |
| Pass | Yes | - | Comment, skip |
| Fail | - | - | Skip |
| Pending | - | - | Skip |

### Step 3: Merge

If approved:
```bash
gh pr merge <number> --squash --delete-branch
```

### Step 4: Update Beads

Extract task ID from branch name and update:
```bash
# Branch: agent/lt-a1b2 -> task ID: lt-a1b2
TASK_ID=$(gh pr view <number> --json headRefName -q '.headRefName | sub("agent/"; "")')
bd update "$TASK_ID" --meta phase=merged
bd close "$TASK_ID"
```

### Step 5: Cleanup Worktree

```bash
WORKTREE=$(bd show "$TASK_ID" --json | jq -r '.meta.worktree')
[ -d "$WORKTREE" ] && git worktree remove "$WORKTREE" --force
```

## Review Guidelines

### Approve If:
- CI passes
- Changes implement the task as described
- Tests are included and pass
- Code follows project conventions
- No security vulnerabilities

### Request Changes If:
- Missing tests
- Obvious bugs
- Security concerns
- Scope creep (changes beyond task)

### Skip If:
- CI still running
- CI failing
- Merge conflicts

## Requesting Changes

```bash
gh pr review <number> --request-changes --body "Please address:
- <issue 1>
- <issue 2>"
```

## Summary Report

After processing all PRs, report:
- PRs merged: X
- PRs skipped (CI pending): X
- PRs skipped (conflicts): X
- PRs needing changes: X

## Rules

1. **Never force merge** - If CI fails, wait or skip
2. **Squash commits** - Keep history clean
3. **Delete branches** - Clean up after merge
4. **Update beads** - Keep state in sync
5. **Be conservative** - When in doubt, skip and let human review
```

### 2. Create Merger Runner Script

Create `scripts/run-merger.sh`:

```bash
#!/bin/bash
set -euo pipefail

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# Stats
merged=0
skipped_ci=0
skipped_conflict=0
needs_changes=0

log "Starting merger agent"

# Get all agent PRs
gh pr list --json number,title,headRefName,mergeable,statusCheckRollup \
    --jq '.[] | select(.headRefName | startswith("agent/"))' | \
while read -r pr_json; do
    pr_num=$(echo "$pr_json" | jq -r '.number')
    title=$(echo "$pr_json" | jq -r '.title')
    branch=$(echo "$pr_json" | jq -r '.headRefName')
    mergeable=$(echo "$pr_json" | jq -r '.mergeable')
    ci_state=$(echo "$pr_json" | jq -r '.statusCheckRollup.state // "SUCCESS"')

    log "Processing PR #$pr_num: $title"

    # Check CI
    if [ "$ci_state" != "SUCCESS" ]; then
        log "  Skipping: CI $ci_state"
        ((skipped_ci++)) || true
        continue
    fi

    # Check conflicts
    if [ "$mergeable" = "CONFLICTING" ]; then
        log "  Skipping: has conflicts"
        gh pr comment "$pr_num" --body "This PR has merge conflicts. Please rebase on main." 2>/dev/null || true
        ((skipped_conflict++)) || true
        continue
    fi

    if [ "$mergeable" != "MERGEABLE" ]; then
        log "  Skipping: not mergeable ($mergeable)"
        ((skipped_ci++)) || true
        continue
    fi

    # Merge
    log "  Merging PR #$pr_num"
    if gh pr merge "$pr_num" --squash --delete-branch; then
        ((merged++)) || true

        # Update beads
        task_id=${branch#agent/}
        bd update "$task_id" --meta phase=merged 2>/dev/null || true
        bd close "$task_id" 2>/dev/null || true

        # Cleanup worktree
        worktree=$(bd show "$task_id" --json 2>/dev/null | jq -r '.meta.worktree // empty')
        [ -n "$worktree" ] && [ -d "$worktree" ] && git worktree remove "$worktree" --force 2>/dev/null || true

        log "  Merged and cleaned up"
    else
        log "  Merge failed"
    fi
done

log "Summary: merged=$merged, skipped_ci=$skipped_ci, skipped_conflict=$skipped_conflict"
```

### 3. Make Script Executable

```bash
chmod +x scripts/run-merger.sh
```

## Test Cases

### Test 1: PR Detection
```bash
#!/bin/bash
# Verify merger can list PRs (may be empty)
gh pr list --json number,headRefName \
    --jq '[.[] | select(.headRefName | startswith("agent/"))] | length' || exit 1
echo "PASS: PR detection"
```

### Test 2: Merge Decision Logic
```bash
#!/bin/bash
# Test jq filters for merge decisions
echo '{"mergeable": "MERGEABLE", "statusCheckRollup": {"state": "SUCCESS"}}' | \
    jq -e 'if .mergeable == "MERGEABLE" and .statusCheckRollup.state == "SUCCESS" then true else false end' || exit 1
echo "PASS: merge decision logic"
```

## Verification Checklist

- [ ] `.claude/agents/merger.md` created
- [ ] `scripts/run-merger.sh` created and executable
- [ ] Script checks CI status before merge
- [ ] Script checks merge conflicts
- [ ] Script uses squash merge
- [ ] Script deletes branch after merge
- [ ] Script updates Beads on success
- [ ] Script cleans up worktrees

## Notes

- The merger can run as part of the orchestrator loop or standalone
- Consider adding `--dry-run` flag for testing
- GitHub API has rate limits - add retry logic for production use
- For large teams, consider requiring human approval for certain PRs

## Files to Modify

- `.claude/agents/merger.md` - Create merger agent prompt
- `scripts/run-merger.sh` - Create merger runner script

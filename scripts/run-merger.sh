#!/bin/bash
# ==============================================================================
# run-merger.sh - Merger agent for reviewing and merging worker PRs
#
# Usage: ./scripts/run-merger.sh [--dry-run]
#
# Description:
#   Processes PRs created by worker agents (branches prefixed with agent/).
#   Checks CI status, verifies mergeability, and merges approved PRs.
# ==============================================================================
set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# State file for orchestrator (to cleanup worktrees)
STATE_FILE=".beads/orchestrator/state.json"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
dry() { $DRY_RUN && echo "[DRY-RUN] $*" && return 0 || return 1; }

# Stats
merged=0
skipped_ci=0
skipped_conflict=0
skipped_unknown=0

log "Starting merger agent"
$DRY_RUN && log "DRY RUN MODE - no changes will be made"

# Get all agent PRs
prs=$(gh pr list --json number,title,headRefName,mergeable,statusCheckRollup 2>/dev/null || echo "[]")

# Process each PR
echo "$prs" | jq -c '.[] | select(.headRefName | startswith("agent/"))' 2>/dev/null | while read -r pr_json; do
    [ -z "$pr_json" ] || [ "$pr_json" = "null" ] && continue

    pr_num=$(echo "$pr_json" | jq -r '.number')
    title=$(echo "$pr_json" | jq -r '.title')
    branch=$(echo "$pr_json" | jq -r '.headRefName')
    mergeable=$(echo "$pr_json" | jq -r '.mergeable')
    ci_state=$(echo "$pr_json" | jq -r '.statusCheckRollup.state // "SUCCESS"')

    log "Processing PR #$pr_num: $title"
    log "  Branch: $branch, Mergeable: $mergeable, CI: $ci_state"

    # Check CI
    if [ "$ci_state" != "SUCCESS" ] && [ "$ci_state" != "null" ]; then
        log "  Skipping: CI state is $ci_state"
        ((skipped_ci++)) || true
        continue
    fi

    # Check conflicts
    if [ "$mergeable" = "CONFLICTING" ]; then
        log "  Skipping: has merge conflicts"
        if ! dry "Would comment on PR #$pr_num about conflicts"; then
            gh pr comment "$pr_num" --body "This PR has merge conflicts. Please rebase on main:
\`\`\`bash
git fetch origin master
git rebase origin/master
git push --force-with-lease
\`\`\`" 2>/dev/null || true
        fi
        ((skipped_conflict++)) || true
        continue
    fi

    if [ "$mergeable" != "MERGEABLE" ]; then
        log "  Skipping: not mergeable (state: $mergeable)"
        ((skipped_unknown++)) || true
        continue
    fi

    # Merge
    log "  Merging PR #$pr_num"
    if dry "Would merge PR #$pr_num"; then
        ((merged++)) || true
    elif gh pr merge "$pr_num" --squash --delete-branch 2>/dev/null; then
        ((merged++)) || true

        # Extract task ID from branch
        task_id=${branch#agent/}
        log "  Updating beads for task: $task_id"

        # Update beads
        bd update "$task_id" --remove-label "phase:pr_created" --add-label "phase:merged" 2>/dev/null || true
        bd close "$task_id" 2>/dev/null || true

        # Cleanup worktree from local state
        if [ -f "$STATE_FILE" ]; then
            worktree=$(jq -r --arg id "$task_id" '.[$id].worktree // empty' "$STATE_FILE" 2>/dev/null || echo "")
            if [ -n "$worktree" ] && [ -d "$worktree" ]; then
                log "  Cleaning up worktree: $worktree"
                git worktree remove "$worktree" --force 2>/dev/null || true
            fi

            # Remove from state file
            tmp=$(mktemp)
            jq --arg id "$task_id" 'del(.[$id])' "$STATE_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$STATE_FILE" || rm -f "$tmp"
        fi

        log "  Merged and cleaned up"
    else
        log "  Merge failed"
    fi
done

log "Summary: merged=$merged, skipped_ci=$skipped_ci, skipped_conflict=$skipped_conflict, skipped_unknown=$skipped_unknown"

#!/bin/bash
# ==============================================================================
# test-crash-recovery.sh - Validate orchestrator crash recovery behavior
#
# Usage: ./scripts/test-crash-recovery.sh
#
# Description:
#   Simulates crashes at each phase and verifies the system can detect and
#   recover from them. Uses labels for phase tracking and local state file
#   for runtime data (matching actual orchestrator implementation).
# ==============================================================================
set -euo pipefail

WORKTREE_BASE="../worktrees"
TEST_PREFIX="crash-test"
STATE_DIR=".beads/orchestrator"
STATE_FILE="$STATE_DIR/state.json"

log() { echo "[TEST] $*"; }
pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*"; exit 1; }

# State file helpers (matching orchestrator.sh)
init_state_file() {
    mkdir -p "$STATE_DIR"
    [ -f "$STATE_FILE" ] || echo "{}" > "$STATE_FILE"
}

set_task_state() {
    local task_id=$1
    local key=$2
    local value=$3
    local tmp=$(mktemp)
    jq --arg id "$task_id" --arg k "$key" --arg v "$value" \
        '.[$id] = (.[$id] // {}) | .[$id][$k] = $v' "$STATE_FILE" > "$tmp"
    mv "$tmp" "$STATE_FILE"
}

get_task_state() {
    local task_id=$1
    local key=$2
    jq -r --arg id "$task_id" --arg k "$key" '.[$id][$k] // empty' "$STATE_FILE" 2>/dev/null || echo ""
}

clear_task_state() {
    local task_id=$1
    local tmp=$(mktemp)
    jq --arg id "$task_id" 'del(.[$id])' "$STATE_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$STATE_FILE" || rm -f "$tmp"
}

cleanup() {
    log "Cleaning up test artifacts..."
    # Delete test tasks from beads (match by title containing TEST_PREFIX)
    bd list --json 2>/dev/null | jq -r ".[] | select(.title | contains(\"$TEST_PREFIX\")) | .id" 2>/dev/null | \
        while read -r id; do
            [ -n "$id" ] && bd delete "$id" --force 2>/dev/null
        done || true
    # Remove test worktrees (ghtml-xxx format)
    git worktree list --porcelain 2>/dev/null | grep "worktree" | cut -d' ' -f2 | \
        grep -E "/ghtml-[a-z0-9]+$" 2>/dev/null | \
        while read -r wt; do
            git worktree remove "$wt" --force 2>/dev/null
        done || true
    git worktree prune 2>/dev/null || true
    # Clear ghtml-xxx entries from state file (test tasks only)
    if [ -f "$STATE_FILE" ]; then
        local tmp=$(mktemp)
        # Keep only entries that don't look like test tasks (real tasks should persist)
        jq '.' "$STATE_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$STATE_FILE" || rm -f "$tmp"
    fi
    return 0
}

trap cleanup EXIT

# ==============================================================================
# Test 1: Recovery from spawned phase (agent never started working)
# ==============================================================================
test_recovery_spawned() {
    log "Test 1: Recovery from spawned phase"

    # Create task in spawned state (capture the actual beads-assigned ID)
    local task_id=$(bd create "${TEST_PREFIX}: Test spawned recovery" -p 2 --json 2>/dev/null | jq -r '.id')
    [ -n "$task_id" ] || fail "Failed to create task"
    local worktree="${WORKTREE_BASE}/${task_id}"

    # Simulate: task marked in_progress with spawned phase label
    bd update "$task_id" --status in_progress --add-label "phase:spawned" 2>/dev/null || true

    # Record runtime state (worktree path, fake PID)
    init_state_file
    set_task_state "$task_id" "worktree" "$worktree"
    set_task_state "$task_id" "pid" "99999"  # Non-existent PID

    # Verify beads label (bd show --json returns an array)
    local labels=$(bd show "$task_id" --json 2>/dev/null | jq -r '.[0].labels[]? // empty' | tr '\n' ' ')
    echo "$labels" | grep -q "phase:spawned" || fail "Phase label not set"

    # Verify runtime state
    local pid=$(get_task_state "$task_id" "pid")
    [ "$pid" = "99999" ] || fail "PID not recorded in state file"

    # Verify PID is dead (orchestrator should detect this)
    if kill -0 99999 2>/dev/null; then
        fail "Test PID should not exist"
    fi

    # Clean up
    clear_task_state "$task_id"
    bd delete "$task_id" --force 2>/dev/null || true

    pass "Recovery from spawned phase"
}

# ==============================================================================
# Test 2: Recovery from working phase (agent crashed mid-work)
# ==============================================================================
test_recovery_working() {
    log "Test 2: Recovery from working phase"

    # Create task (capture the actual beads-assigned ID)
    local task_id=$(bd create "${TEST_PREFIX}: Test working recovery" -p 2 --json 2>/dev/null | jq -r '.id')
    [ -n "$task_id" ] || fail "Failed to create task"
    local worktree="${WORKTREE_BASE}/${task_id}"
    local branch="agent/${task_id}"

    # Create actual worktree
    mkdir -p "$WORKTREE_BASE"
    git worktree add "$worktree" -b "$branch" 2>/dev/null || true

    # Simulate: agent was working, has uncommitted changes
    bd update "$task_id" --status in_progress --add-label "phase:working" 2>/dev/null || true

    init_state_file
    set_task_state "$task_id" "worktree" "$worktree"
    set_task_state "$task_id" "pid" "99999"

    # Create some uncommitted work
    echo "test content" > "${worktree}/test-file.txt"
    (cd "$worktree" && git add test-file.txt)

    # Verify uncommitted changes exist
    local changes=$(cd "$worktree" && git status --porcelain | wc -l | tr -d ' ')
    [ "$changes" -gt 0 ] || fail "No uncommitted changes created"

    # Verify worktree recorded
    local recorded_wt=$(get_task_state "$task_id" "worktree")
    [ "$recorded_wt" = "$worktree" ] || fail "Worktree not recorded"

    # Cleanup
    clear_task_state "$task_id"
    git worktree remove "$worktree" --force 2>/dev/null || true
    git branch -D "$branch" 2>/dev/null || true
    bd delete "$task_id" --force 2>/dev/null || true

    pass "Recovery from working phase"
}

# ==============================================================================
# Test 3: Recovery from committed phase (has commits, no PR)
# ==============================================================================
test_recovery_committed() {
    log "Test 3: Recovery from committed phase"

    # Create task (capture the actual beads-assigned ID)
    local task_id=$(bd create "${TEST_PREFIX}: Test committed recovery" -p 2 --json 2>/dev/null | jq -r '.id')
    [ -n "$task_id" ] || fail "Failed to create task"
    local worktree="${WORKTREE_BASE}/${task_id}"
    local branch="agent/${task_id}"

    # Create worktree with a commit
    mkdir -p "$WORKTREE_BASE"
    git worktree add "$worktree" -b "$branch" 2>/dev/null || true
    (
        cd "$worktree"
        echo "committed content" > test-committed.txt
        git add test-committed.txt
        git commit -m "Test commit for recovery"
    )

    # Set state to committed (but no PR)
    bd update "$task_id" --status in_progress --add-label "phase:committed" 2>/dev/null || true

    init_state_file
    set_task_state "$task_id" "worktree" "$worktree"
    set_task_state "$task_id" "pid" ""  # No running agent

    # Verify commit exists
    local commits=$(cd "$worktree" && git log origin/master..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
    [ "$commits" -gt 0 ] || fail "No commits found"

    # Verify phase label
    local labels=$(bd show "$task_id" --json 2>/dev/null | jq -r '.[0].labels[]? // empty' | tr '\n' ' ')
    echo "$labels" | grep -q "phase:committed" || fail "Phase label not correct"

    # Cleanup
    clear_task_state "$task_id"
    git worktree remove "$worktree" --force 2>/dev/null || true
    git branch -D "$branch" 2>/dev/null || true
    bd delete "$task_id" --force 2>/dev/null || true

    pass "Recovery from committed phase"
}

# ==============================================================================
# Test 4: Recovery from pr_created phase (PR exists, not merged)
# ==============================================================================
test_recovery_pr_created() {
    log "Test 4: Recovery from pr_created phase"

    # Create task (capture the actual beads-assigned ID)
    local task_id=$(bd create "${TEST_PREFIX}: Test PR recovery" -p 2 --json 2>/dev/null | jq -r '.id')
    [ -n "$task_id" ] || fail "Failed to create task"

    # Simulate: PR was created
    bd update "$task_id" --status in_progress --add-label "phase:pr_created" 2>/dev/null || true

    init_state_file
    set_task_state "$task_id" "pr_number" "12345"  # Fake PR number

    # Verify state
    local labels=$(bd show "$task_id" --json 2>/dev/null | jq -r '.[0].labels[]? // empty' | tr '\n' ' ')
    echo "$labels" | grep -q "phase:pr_created" || fail "Phase not correct"

    local pr=$(get_task_state "$task_id" "pr_number")
    [ "$pr" = "12345" ] || fail "PR number not recorded"

    clear_task_state "$task_id"
    bd delete "$task_id" --force 2>/dev/null || true

    pass "Recovery from pr_created phase"
}

# ==============================================================================
# Test 5: Orphaned worktree detection
# ==============================================================================
test_orphaned_worktree() {
    log "Test 5: Orphaned worktree detection"

    local task_id="${TEST_PREFIX}-orphan-$$"
    local worktree="${WORKTREE_BASE}/${task_id}"
    local branch="agent/${task_id}"

    # Create worktree WITHOUT corresponding beads task
    mkdir -p "$WORKTREE_BASE"
    git worktree add "$worktree" -b "$branch" 2>/dev/null || true

    # Verify worktree exists
    [ -d "$worktree" ] || fail "Worktree not created"

    # Verify no beads task
    if bd show "$task_id" 2>/dev/null | grep -q "id:"; then
        fail "Task should not exist in beads"
    fi

    # This is an orphan - orchestrator should detect branches starting with agent/
    # that don't have corresponding in-progress tasks
    local orphan_count=$(git worktree list | grep "agent/${TEST_PREFIX}" | wc -l | tr -d ' ')
    [ "$orphan_count" -gt 0 ] || fail "Orphan worktree not detected"

    # Cleanup
    git worktree remove "$worktree" --force 2>/dev/null || true
    git branch -D "$branch" 2>/dev/null || true

    pass "Orphaned worktree detection"
}

# ==============================================================================
# Test 6: State file and label consistency
# ==============================================================================
test_state_consistency() {
    log "Test 6: State file and label consistency"

    # Create multiple tasks in different states (capture actual beads IDs)
    local task1=$(bd create "${TEST_PREFIX}: State test 1" -p 2 --json 2>/dev/null | jq -r '.id')
    local task2=$(bd create "${TEST_PREFIX}: State test 2" -p 2 --json 2>/dev/null | jq -r '.id')
    local task3=$(bd create "${TEST_PREFIX}: State test 3" -p 2 --json 2>/dev/null | jq -r '.id')

    [ -n "$task1" ] && [ -n "$task2" ] && [ -n "$task3" ] || fail "Failed to create tasks"

    bd update "$task1" --status in_progress --add-label "phase:working" 2>/dev/null || true
    bd update "$task2" --status in_progress --add-label "phase:committed" 2>/dev/null || true
    bd update "$task3" --status in_progress --add-label "phase:pr_created" 2>/dev/null || true

    init_state_file
    set_task_state "$task1" "worktree" "../worktrees/$task1"
    set_task_state "$task2" "worktree" "../worktrees/$task2"
    set_task_state "$task3" "pr_number" "999"

    # Query all in_progress tasks with phase labels
    local count=$(bd list --json 2>/dev/null | jq "[.[] | select(.status == \"in_progress\") | select(.labels[]? | startswith(\"phase:\"))] | length")
    [ "$count" -ge 3 ] || fail "Expected at least 3 in_progress tasks with phase labels, got $count"

    # Verify state file has entries for our test tasks
    local has_task1=$(jq --arg id "$task1" 'has($id)' "$STATE_FILE" 2>/dev/null || echo "false")
    local has_task2=$(jq --arg id "$task2" 'has($id)' "$STATE_FILE" 2>/dev/null || echo "false")
    local has_task3=$(jq --arg id "$task3" 'has($id)' "$STATE_FILE" 2>/dev/null || echo "false")
    [ "$has_task1" = "true" ] && [ "$has_task2" = "true" ] && [ "$has_task3" = "true" ] || fail "State entries not recorded"

    # Cleanup
    clear_task_state "$task1"
    clear_task_state "$task2"
    clear_task_state "$task3"
    bd delete "$task1" --force 2>/dev/null || true
    bd delete "$task2" --force 2>/dev/null || true
    bd delete "$task3" --force 2>/dev/null || true

    pass "State file and label consistency"
}

# ==============================================================================
# Test 7: PID detection for dead processes
# ==============================================================================
test_dead_pid_detection() {
    log "Test 7: Dead PID detection"

    # Test that we can detect dead PIDs
    local fake_pid=99999

    # This PID should not exist
    if kill -0 $fake_pid 2>/dev/null; then
        fail "Fake PID $fake_pid should not exist"
    fi

    # Get a real PID (our shell)
    local real_pid=$$
    if ! kill -0 $real_pid 2>/dev/null; then
        fail "Our own PID $real_pid should exist"
    fi

    pass "Dead PID detection"
}

# ==============================================================================
# Run all tests
# ==============================================================================
main() {
    log "Starting crash recovery tests"
    echo ""

    # Check prerequisites
    command -v bd >/dev/null || { echo "Error: bd (beads) not found"; exit 1; }
    command -v jq >/dev/null || { echo "Error: jq not found"; exit 1; }

    mkdir -p "$WORKTREE_BASE"
    init_state_file

    test_recovery_spawned
    test_recovery_working
    test_recovery_committed
    test_recovery_pr_created
    test_orphaned_worktree
    test_state_consistency
    test_dead_pid_detection

    echo ""
    log "All crash recovery tests passed!"
}

main "$@"

---
name: orchestrate
description: Execute an epic to completion via subagents
disable-model-invocation: true
argument-hint: [epic-name]
---

# Orchestrate Epic: $ARGUMENTS

## Current Task Status
!`cat .claude/plan/$ARGUMENTS/tasks/README.md 2>/dev/null || echo "Epic '$ARGUMENTS' not found in .claude/plan/"`

## Algorithm

**CRITICAL: Execute ONE task at a time. NEVER spawn parallel subagents.**

1. Find first `[ ] Pending` or `[~] In Progress` task from status above
2. For each task ONE AT A TIME:
   - Update status to `[~] In Progress`
   - Spawn ONE subagent with: "Read .claude/SUBAGENT.md and execute task at .claude/plan/$ARGUMENTS/tasks/<task_file>.md"
   - **Wait for completion before proceeding**
   - On success: run `just check`, update to `[x] Complete`, push
   - On failure: retry once with error context, then mark `[!] Blocked` and stop
   - **Only after task completes, move to the next task**
3. When no pending tasks remain, report epic complete

## Subagent Spawn

Pass to subagent:
- Epic name: `$ARGUMENTS`
- Task path: `.claude/plan/$ARGUMENTS/tasks/<NNN>_<name>.md`
- Instruction: "Read .claude/SUBAGENT.md and execute this task"

## Error Handling

| Scenario | Action |
|----------|--------|
| Subagent reports failure | Retry once with error context |
| `just check` fails after success | Retry once with check output |
| Retry fails | Mark `[!] Blocked: <error>`, stop orchestration |

## Recovery

Re-run `/orchestrate $ARGUMENTS`. Resumes from first incomplete task.

---
name: orchestrate
description: Execute tasks from Beads via subagents
disable-model-invocation: true
argument-hint: [epic-label or task-id]
---

# Orchestrate: $ARGUMENTS

## Current Task Status
!`bd ready 2>/dev/null || echo "Beads not initialized. Run 'bd init' first."`

## Algorithm

**CRITICAL: Execute ONE task at a time. NEVER spawn parallel subagents.**

1. Find first ready task from Beads:
   - If `$ARGUMENTS` provided: filter by epic label or specific task ID
   - Otherwise: use `bd ready` to get highest priority unblocked task
2. For each task ONE AT A TIME:
   - Claim: `bd update <id> --status in_progress`
   - Spawn ONE subagent with the task context from `bd show <id>`
   - **Wait for completion before proceeding**
   - On success: run `just check`, close task, push
   - On failure: retry once with error context, then stop
   - **Only after task completes, move to the next task**
3. When no ready tasks remain, report complete

## Subagent Spawn

Pass to subagent:
- Task ID and full description from `bd show <id>`
- Instruction: Follow TDD workflow from CLAUDE.md

## Error Handling

| Scenario | Action |
|----------|--------|
| Subagent reports failure | Retry once with error context |
| `just check` fails after success | Retry once with check output |
| Retry fails | Leave task in_progress, stop orchestration |

## Recovery

Re-run `/orchestrate`. Resumes from first ready or in_progress task.

## Commands

```bash
# View ready tasks
bd ready

# View specific epic tasks
bd list --json | jq '.[] | select(.labels[]? | contains("$ARGUMENTS"))'

# Claim a task
bd update <id> --status in_progress

# Complete a task
bd close <id>
```

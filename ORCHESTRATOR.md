# Epic Orchestration

Execute an epic to completion using subagents.

## Invocation

```
Execute epic: <epic_name>
```

## Algorithm

1. Parse `.plan/<epic>/tasks/README.md` for task list and statuses
2. Find first `[ ] Pending` or `[~] In Progress` task (by number order)
3. For each task sequentially:
   - Update README.md status to `[~] In Progress`
   - Spawn subagent with: epic name, task file path
   - Wait for completion
   - On success: run `just check`, update to `[x] Complete`, push to remote
   - On failure: retry once with error context, then mark `[!] Blocked` and stop
4. When no pending tasks remain, report epic complete

## Subagent Spawn

Pass to subagent:
- Epic name: `<epic_name>`
- Task path: `.plan/<epic>/tasks/<NNN>_<name>.md`
- Instruction: "Read SUBAGENT.md and execute this task"

## Error Handling

| Scenario | Action |
|----------|--------|
| Subagent reports failure | Retry once with error context |
| `just check` fails after success | Retry once with check output |
| Retry fails | Mark `[!] Blocked: <error>`, stop orchestration |

## Recovery

Re-run with same epic name. Resumes from first incomplete task.

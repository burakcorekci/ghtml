# Manual Task Execution

Step-by-step instructions for executing a single task from an epic in **manual mode**.

> **Note:** This is for sequential, human-orchestrated work. For parallel automated execution with multiple agents, see `.claude/docs/orchestration.md`.

## Before Starting

1. Read `.claude/CODEBASE.md` for architecture context
2. Read your assigned task file at `.claude/plan/<epic>/tasks/<NNN>_<name>.md`

## Execution Steps

1. **Update status** in `.claude/plan/<epic>/tasks/README.md`: `[ ] Pending` → `[~] In Progress`

2. **Implement with TDD**:
   - Write failing tests first
   - Implement simplest solution that passes
   - Refactor to clean state

3. **Verify completion**:
   - Meet all success criteria in task file
   - Check off verification checklist items
   - Run `just check` - all checks must pass

4. **Update tracking**:
   - Status in README.md: `[~] In Progress` → `[x] Complete`
   - Completion checklist in PLAN.md if one exists
   - Update `.claude/CODEBASE.md` if task added new modules, changed architecture, or introduced new patterns

5. **Commit and push**:
   ```
   <concise description>

   epic: <epic_name>
   task: <task_name>
   ```

6. **Report** success or failure with details

## Status Legend

| Status | Meaning |
|--------|---------|
| `[ ] Pending` | Not started |
| `[~] In Progress` | Currently being worked on |
| `[x] Complete` | Finished and verified |
| `[!] Blocked` | Waiting on dependency or stuck |

## On Failure

- Report what failed and why
- Include error output
- Do not commit partial work
- Mark status as `[!] Blocked: <reason>`

## Comparison with Automated Mode

| Aspect | Manual (this doc) | Automated |
|--------|-------------------|-----------|
| Status tracking | `.claude/plan/` README.md | Beads |
| Orchestration | Human | Script |
| Parallelism | No | Yes |
| PR workflow | Optional | Built-in |
| Best for | Single tasks, learning | Multiple independent tasks |

To switch to automated mode, see `.claude/docs/orchestration.md`.

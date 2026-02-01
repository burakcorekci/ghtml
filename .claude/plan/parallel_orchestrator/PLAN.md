# Epic: Parallel Orchestrator

## Goal

Implement a crash-resilient parallel agent orchestration system using a hybrid approach: `.specs/` for discoverable documentation (research, requirements, design) and Beads for queryable execution state.

## Background

The current `.plan/` folder approach works well for sequential, human-orchestrated workflows but lacks machine-queryable state needed for parallel subagent coordination. Research identified:

1. **Kiro/Spec-Kit** - Excel at structured specs but lack queryable execution state
2. **Beads** - Excels at execution tracking but specs aren't easily discoverable
3. **Hybrid approach** - `.specs/` for Grep/Glob discovery + Beads for orchestration

See:
- `.claude/research/task_management_alternatives.md`
- `.claude/research/spec_driven_beads_integration.md`

## Scope

### In Scope

- Hybrid storage: `.specs/` (discoverable) + `.beads/` (queryable)
- EARS notation for unambiguous requirements
- Orchestrator script with epic filtering
- Worker/merger agent configuration
- Crash recovery from any failure point
- Justfile integration

### Out of Scope

- Web UI for monitoring
- Slack/Discord notifications
- Custom agent types beyond worker/merger
- Cross-repository orchestration

## Requirements (EARS Format)

### REQ-001: Task State Query
WHEN an agent needs current task state
THE orchestrator SHALL query Beads via `bd ready` or `bd list --json`
AND return only tasks matching the epic filter

### REQ-002: Parallel Execution
WHILE multiple tasks are unblocked
THE orchestrator SHALL spawn worker agents in parallel up to max-agents limit
AND each agent SHALL work in an isolated git worktree

### REQ-003: Crash Recovery
WHEN the orchestrator restarts after a crash
THE orchestrator SHALL reconstruct state from Beads metadata
AND resume operations without duplicate work or data loss

### REQ-004: Agent Crash Detection
WHILE a task is in_progress
WHEN the agent PID is no longer running
THE orchestrator SHALL detect the stale PID
AND respawn the agent or advance the task phase based on committed work

### REQ-005: PR Auto-Merge
WHILE CI checks are passing AND PR has no merge conflicts
WHEN the merger agent runs
THE merger agent SHALL squash-merge the PR AND delete the branch AND close the Beads task

### REQ-006: Spec Discovery
WHEN an agent explores the codebase for context
THE agent SHALL be able to discover specs via Grep/Glob on `.specs/`
AND find related tasks via Beads metadata links

### REQ-007: State Single Source
THE system SHALL store execution state only in Beads
AND specs/research only in `.specs/` markdown files
AND link them via `meta.spec_file` in Beads issues

## Design Overview

### Hybrid Storage Architecture

```
.specs/                              # Discoverable (Grep/Glob/Read)
├── parallel_orchestrator/
│   ├── README.md                    # Epic overview
│   ├── requirements.md              # EARS requirements (this section)
│   ├── design.md                    # Architecture details
│   └── research/
│       ├── task_management.md       # Alternatives analysis
│       └── spec_driven_beads.md     # Integration research

.beads/                              # Queryable (bd commands)
└── issues.jsonl
    ├── epic: links to .specs/parallel_orchestrator/
    ├── task: meta.spec_file, meta.implements
    └── task: status, phase, dependencies
```

### Orchestrator Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR                              │
│  (Stateless - reconstructs from Beads each cycle)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────┐     ┌─────────────┐     ┌─────────────────────┐  │
│   │  Beads  │────▶│  Worktree   │────▶│   Worker Agents     │  │
│   │  Queue  │     │  Spawner    │     │   (parallel)        │  │
│   └─────────┘     └─────────────┘     └──────────┬──────────┘  │
│       │                                          │              │
│       │ state: in_progress                       │              │
│       │ meta.phase: working                      ▼              │
│       │ meta.worktree: ../worktrees/X   ┌───────────────────┐  │
│       │ meta.spec_file: .specs/.../...  │  gh pr create     │  │
│       │ meta.pr_number: 42              └─────────┬─────────┘  │
│       │                                           │              │
│       │                                           ▼              │
│       │                                 ┌───────────────────┐  │
│       └────────────────────────────────▶│  Merger Agent     │  │
│                                         │  (reviews/merges) │  │
│                                         └───────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Task State Machine

```
status: open           status: in_progress              status: closed
┌──────────┐          ┌─────────────────────┐          ┌──────────┐
│  Ready   │─────────▶│ phase: spawned      │          │  Done    │
│  (queue) │          │ phase: working      │─────────▶│          │
└──────────┘          │ phase: committed    │          └──────────┘
                      │ phase: pr_created   │
                      │ phase: merged       │
                      └─────────────────────┘
```

## Task Breakdown

| # | Task | Description | Dependencies | Implements |
|---|------|-------------|--------------|------------|
| 001 | Initialize Beads | Set up beads, verify installation | None | REQ-001 |
| 001b | Spec Structure | Create .specs/, EARS conventions, justfile | 001 | REQ-006, REQ-007 |
| 002 | Core Orchestrator | Stateless orchestrator with state reconstruction | 001b | REQ-001, REQ-002, REQ-003 |
| 003 | Worker Agent | Worker prompt, phase updates, PR creation | 001b | REQ-002 |
| 004 | Merger Agent | PR review, auto-merge, cleanup | 001b | REQ-005 |
| 005 | Justfile Integration | Orchestration commands | 002, 003, 004 | - |
| 006 | Crash Recovery Tests | Validate recovery at each phase | 005 | REQ-003, REQ-004 |
| 007 | Documentation | Usage guide, conventions | 006 | - |
| 008 | Migrate Existing | Move .plan/ content to .specs/ + Beads | 007 | - |
| 009 | Cleanup Legacy | Remove .plan/, simplify CLAUDE.md | 008 | - |

## Task Dependency Graph

```
001_initialize_beads
         │
         ▼
001b_spec_structure
         │
         ├──────────────────┬──────────────────┐
         ▼                  ▼                  ▼
002_orchestrator       003_worker         004_merger
         │                  │                  │
         └──────────────────┴──────────────────┘
                            │
                            ▼
                   005_justfile
                            │
                            ▼
                   006_crash_tests
                            │
                            ▼
                   007_documentation
                            │
                            ▼
                   008_migrate
                            │
                            ▼
                   009_cleanup
```

## Success Criteria

1. WHEN `just orchestrate --epic <id>` is run THEN parallel agents spawn for all ready tasks
2. WHEN `bd list --json` is queried THEN all orchestration state is returned
3. WHEN orchestrator crashes and restarts THEN it recovers without data loss
4. WHEN worker creates PR and CI passes THEN merger auto-merges
5. WHEN task completes THEN worktree is cleaned up
6. WHEN agent needs context THEN it can Grep `.specs/` and find relevant research

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Beads CLI not installed | High | Task 001 verifies installation |
| Race conditions in Beads | Medium | Hash-based IDs prevent conflicts |
| Worktree disk space | Medium | Cleanup in orchestrator loop |
| GitHub API rate limits | Low | Retry with backoff |
| Agent crashes silently | Medium | PID tracking + phase detection |
| Specs out of sync with Beads | Medium | Migration script validates links |

## Open Questions

- [x] Hierarchical IDs or labels for epic filtering? → Hierarchical IDs
- [x] Where should orchestrator state live? → Beads metadata only
- [x] How do agents discover research/specs? → Grep/Glob on `.specs/`
- [ ] Should merger agent run continuously or be triggered?
- [ ] How to handle PRs with merge conflicts?

## References

- Research: `.claude/research/task_management_alternatives.md`
- Spec integration: `.claude/research/spec_driven_beads_integration.md`
- Beads: https://github.com/steveyegge/beads
- Git worktrees: https://git-scm.com/docs/git-worktree
- Kiro: https://kiro.dev/docs/specs/
- EARS: https://alistairmavin.com/ears/

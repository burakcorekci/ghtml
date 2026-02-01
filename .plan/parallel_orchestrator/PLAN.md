# Epic: Parallel Orchestrator

## Goal

Implement a crash-resilient parallel agent orchestration system using Beads as the single source of truth, git worktrees for isolation, and GitHub PRs for integration.

## Background

The current `.plan/` folder approach works well for sequential, human-orchestrated workflows but lacks machine-queryable state needed for parallel subagent coordination. Research (see `.plan/research/task_management_alternatives.md`) identified that combining:

1. **Beads** - Git-backed task queue with dependency tracking
2. **Git worktrees** - Isolated working directories per agent
3. **GitHub PRs** - Review gate and CI integration
4. **Merger agent** - Automated review and merge

...provides a robust foundation for parallel development that survives crashes and scales to multiple concurrent agents.

## Scope

### In Scope

- Beads integration for task state management
- Orchestrator script with epic filtering
- Worker agent prompt/configuration
- Merger agent for PR review/merge
- Crash recovery from any failure point
- Justfile integration
- Basic validation tests

### Out of Scope

- Web UI for monitoring
- Slack/Discord notifications
- Custom agent types beyond worker/merger
- Cross-repository orchestration
- Kubernetes/cloud deployment

## Design Overview

All orchestration state lives in Beads metadata. The orchestrator is stateless and reconstructs its view on each cycle by querying Beads.

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
│       │ meta.agent_pid: 12345           │  gh pr create     │  │
│       │ meta.pr_number: 42              └─────────┬─────────┘  │
│       │                                           │              │
│       │                                           ▼              │
│       │                                 ┌───────────────────┐  │
│       └────────────────────────────────▶│  Merger Agent     │  │
│                                         │  (reviews/merges) │  │
│                                         └───────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### State Machine (All in Beads)

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

| # | Task | Description | Dependencies |
|---|------|-------------|--------------|
| 001 | Initialize Beads | Set up beads in project, document workflow | None |
| 002 | Core Orchestrator | Main orchestrator script with state reconstruction | 001 |
| 003 | Worker Agent | Worker agent prompt and configuration | 001 |
| 004 | Merger Agent | Merger agent for PR review and merge | 001 |
| 005 | Justfile Integration | Add orchestration commands to justfile | 002, 003, 004 |
| 006 | Crash Recovery Tests | Validate recovery from various failure points | 005 |
| 007 | Documentation | Update CODEBASE.md and create usage guide | 006 |
| 008 | Migrate Existing Epics | Migrate incomplete .plan/ tasks to Beads | 007 |
| 009 | Cleanup Manual Mode | Simplify docs to Beads-first, deprecate manual | 008 |

## Task Dependency Graph

```
001_initialize_beads
         │
         ├──────────────────┬──────────────────┐
         ▼                  ▼                  ▼
002_core_orchestrator  003_worker_agent  004_merger_agent
         │                  │                  │
         └──────────────────┴──────────────────┘
                            │
                            ▼
                   005_justfile_integration
                            │
                            ▼
                   006_crash_recovery_tests
                            │
                            ▼
                   007_documentation
                            │
                            ▼
                   008_migrate_existing_epics
                            │
                            ▼
                   009_cleanup_manual_mode
```

## Success Criteria

1. `just orchestrate --epic <id>` spawns parallel agents for all ready tasks under epic
2. All orchestration state queryable via `bd list --json`
3. System recovers correctly after simulated crash at any phase
4. PRs created by workers are automatically merged when CI passes
5. Worktrees cleaned up after task completion
6. No state stored outside of Beads (except transient PIDs)

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Beads CLI not installed | High | Task 001 includes installation verification |
| Race conditions in Beads updates | Medium | Beads uses hash-based IDs; test concurrent updates |
| Worktree disk space | Medium | Add cleanup in orchestrator loop; document limits |
| GitHub API rate limits | Low | Add retry with backoff in merger agent |
| Agent crashes silently | Medium | PID tracking + timeout detection |

## Open Questions

- [x] Should we use hierarchical IDs or labels for epic filtering? → Hierarchical IDs
- [x] Where should orchestrator state live? → All in Beads metadata
- [ ] Should merger agent run continuously or be triggered?
- [ ] How to handle PRs with merge conflicts?

## References

- Research report: `.plan/research/task_management_alternatives.md`
- Beads documentation: https://github.com/steveyegge/beads
- Git worktrees: https://git-scm.com/docs/git-worktree

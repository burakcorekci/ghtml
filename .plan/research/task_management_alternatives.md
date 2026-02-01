# Task Management Alternatives for Parallel Subagent Usage

**Research Date:** 2026-02-01
**Context:** Evaluating alternatives to the current `.plan/` folder approach that can scale to parallel subagent usage.

---

## Executive Summary

The current `.plan/` folder approach works well for sequential, human-orchestrated workflows but lacks machine-queryable state and automatic dependency resolution needed for parallel subagent coordination. Several alternatives exist, each with distinct trade-offs:

| Solution | Best For | Parallel Support | Complexity |
|----------|----------|------------------|------------|
| Claude Code Native Tasks | Session-scoped work | Built-in | Low |
| Beads | Multi-session, git-native | Hash-based IDs | Medium |
| Git Worktrees + Orchestrator | True isolation | Full isolation | Medium-High |
| Claude-Flow | Enterprise swarms | 60+ agents | High |
| Hybrid Approach | Best of both worlds | Configurable | Medium |

---

## Current Approach: `.plan/` Folder

### How It Works

```
.plan/
├── _template/                    # Templates for new epics
├── initial_implementation/       # Completed epic
│   ├── PLAN.md                   # High-level epic plan
│   └── tasks/
│       ├── README.md             # Task status tracking
│       └── 001_task_name.md      # Individual task specs
└── learning_examples/            # Current epic
```

### Strengths

- **Human-readable**: All context visible in markdown
- **Version-controlled**: Full history of planning decisions
- **Comprehensive templates**: Reduces planning overhead
- **Dependency visualization**: ASCII graphs show task relationships
- **Self-contained**: No external tools required

### Limitations for Parallel Subagents

1. **No machine-queryable state**: Subagents can't ask "what's ready?"
2. **Manual status updates**: Race conditions when parallel agents update
3. **No atomic claims**: Two agents could claim the same task
4. **No automatic unblocking**: Completing a task doesn't signal dependents
5. **Markdown parsing overhead**: Agents waste tokens parsing status tables

---

## Alternative 1: Claude Code Native Tasks

### Overview

Claude Code 2.1+ includes a built-in task system with `TaskCreate`, `TaskUpdate`, `TaskList`, and `TaskGet` tools. This evolved from the community "Ralphie" plugin and is now first-class functionality.

### Key Features

```
TaskCreate:
  - subject: "Implement parser"        # Imperative form
  - activeForm: "Implementing parser"  # Shown in spinner
  - description: "Full details..."
  - metadata: { priority: "P0" }

TaskUpdate:
  - status: pending → in_progress → completed
  - addBlocks: ["task-2"]              # Dependency management
  - addBlockedBy: ["task-1"]
```

### Parallel Subagent Support

- **Automatic blocking**: Tasks track `blockedBy` arrays
- **Ready detection**: Query only unblocked tasks
- **Session-scoped**: Fresh each session (feature, not bug)
- **Spinner integration**: Visual feedback during execution

### Trade-offs

| Pros | Cons |
|------|------|
| Zero setup - built-in | Session-scoped (resets each session) |
| Native subagent integration | No persistence to git |
| Low token overhead | No cross-session memory |
| Dependency-aware | Limited metadata/priority |

### Best For

- Single-session complex tasks
- Within-session parallel subagent work
- Tasks that don't span multiple conversations

---

## Alternative 2: Beads

### Overview

Created by Steve Yegge, Beads is a git-backed, distributed task management system specifically designed for AI agents. It treats persistent memory as a first-class concern.

### Architecture

```
.beads/           # Git-tracked issue database
├── issues.jsonl  # Append-only issue log
└── config.json   # Project configuration

SQLite Cache → Fast local queries
Git Backend → Distributed, versioned, mergeable
```

### Key Features

1. **Dependency-first design**
   ```bash
   bd ready              # Only shows unblocked tasks
   bd dep add A.1 A      # Link child to parent
   bd dep tree           # Visualize hierarchy
   ```

2. **Hash-based IDs** (v0.20.1+)
   ```
   bd-a3f8     # Epic
   bd-a3f8.1   # Task under epic
   bd-a3f8.1.1 # Subtask
   ```
   Prevents merge collisions in multi-agent workflows.

3. **Priority + Readiness System**
   - P0 (Critical) → P1 → P2 → P3 → Backlog
   - `bd ready` combines priority with dependency status

4. **Memory Compaction**
   ```bash
   bd compact  # LLM-summarizes old closed issues
   ```
   Implements "agentic memory decay" for long-running projects.

### Parallel Subagent Support

- **Hash IDs prevent collisions**: Multiple agents can create tasks simultaneously
- **Ready queue**: Agents query `bd ready` for next available work
- **Git merge semantics**: Concurrent edits handled by git
- **No central coordinator**: Fully distributed

### Integration Patterns

```bash
# CLI (recommended for Claude Code - lower token usage)
bd ready --json | jq '.issues[0]'

# MCP Server (for Claude Desktop, no shell access)
# Higher token cost (10-50k vs 1-2k) but works everywhere
```

### "Land the Plane" Pattern

End-of-session handoff workflow:
1. Query `bd ready` for current state
2. Close completed tasks
3. Add new blockers discovered during work
4. Sync git state
5. Generate handoff prompt from highest-priority unblocked work

### Trade-offs

| Pros | Cons |
|------|------|
| Persistent across sessions | External tool dependency |
| Git-native (versioned, distributed) | Learning curve |
| Designed for AI agents | Optimized for <200 tasks |
| Low token overhead (CLI) | Requires shell access |
| Dependency-aware ready queue | |

### Best For

- Multi-session projects
- Teams with multiple AI agents
- Projects needing audit trails
- Work spanning conversation compaction

---

## Alternative 3: Git Worktrees + Orchestrator

### Overview

Git worktrees allow multiple working directories from the same repository, each on different branches. Combined with an orchestrator, this enables true parallel agent isolation.

### How It Works

```bash
# Main repo
/project/
  └── .git/

# Create isolated worktrees
git worktree add ../project-feature-a feature-a
git worktree add ../project-feature-b feature-b
git worktree add ../project-bugfix bugfix-123

# Each worktree gets its own Claude Code instance
```

### Key Insight

> "Operations that depend on repository objects (fetch, gc, hooks, config) are shared; operations that depend on the working directory (add, commit, checkout) are isolated per worktree."

### Available Tools

1. **Agentree** - CLI for creating/managing agent worktrees
2. **Worktree CLI** - Isolated environments with own ports/databases
3. **Uzi** - Lightweight wrapper for parallel agent management via tmux

### Parallel Subagent Support

- **Full isolation**: Each agent has complete working directory
- **No race conditions**: Impossible to conflict on file edits
- **Branch-per-task**: Natural git workflow
- **Merge at end**: Pick best changes or merge all

### Trade-offs

| Pros | Cons |
|------|------|
| True isolation | Disk space (full checkout per worktree) |
| No merge conflicts during work | Merge conflicts at integration |
| Standard git workflow | Requires orchestration layer |
| Works with any AI tool | Complex setup |

### Best For

- Large features with high conflict potential
- "Race" scenarios (multiple solutions, pick best)
- Teams wanting maximum isolation
- Projects with expensive test suites (parallel execution)

---

## Alternative 4: Claude-Flow

### Overview

A comprehensive multi-agent orchestration platform with enterprise features. Transforms Claude Code into a coordinated swarm system.

### Architecture

```
User → Claude-Flow (CLI/MCP) → Router → Swarm → Agents → Memory → LLM
```

### Key Features

- **60+ specialized agents** in coordinated swarms
- **SONA self-learning** system
- **170+ MCP tools** included
- **RuVector** vector database for retrieval
- **Claims**: 84.8% SWE-Bench, 75% cost savings

### CLI Usage

```bash
# Initialize
npx claude-flow@v3alpha init --wizard

# Add as MCP server
claude mcp add claude-flow -- npx -y @claude-flow/cli@latest

# Start swarm
npx claude-flow@v3alpha swarm init --topology hierarchical --max-agents 8

# Spawn agents
npx claude-flow@v3alpha agent spawn -t coder --name my-coder
```

### Trade-offs

| Pros | Cons |
|------|------|
| Enterprise-grade | High complexity |
| Self-learning | Heavy dependency |
| Massive agent count | Learning curve |
| Built-in memory/retrieval | May be overkill |

### Best For

- Large enterprise projects
- Teams needing 10+ parallel agents
- Projects requiring specialized agent types
- Heavy orchestration requirements

---

## Alternative 5: Hybrid Approach

### Concept

Combine the human-readable planning of `.plan/` with machine-queryable execution tracking.

### Implementation Options

**Option A: .plan/ + Native Tasks**
```
.plan/           # Human planning, epic specs
  └── tasks/     # Detailed task specs (read-only reference)

TaskCreate       # Machine state for execution
  └── metadata: { plan_ref: "001_task.md" }
```

**Option B: .plan/ + Beads**
```
.plan/           # High-level planning docs
  └── PLAN.md    # Epic overview, design decisions

.beads/          # Execution tracking
  └── issues     # Machine-queryable task state
```

**Option C: .plan/ + Hydration Pattern**
```python
# tasks.jsonl - Persistent task definitions
{"id": "001", "subject": "Setup", "spec": ".plan/tasks/001_setup.md"}
{"id": "002", "subject": "Parser", "spec": ".plan/tasks/002_parser.md", "blockedBy": ["001"]}

# Session start: Hydrate Native Tasks from JSONL
for task in load("tasks.jsonl"):
    TaskCreate(subject=task.subject, metadata={"spec": task.spec})
```

### Trade-offs

| Pros | Cons |
|------|------|
| Best of both worlds | Two systems to maintain |
| Human + machine readable | Sync overhead |
| Incremental adoption | Complexity |

---

## Comparison Matrix

| Feature | .plan/ | Native Tasks | Beads | Worktrees | Claude-Flow |
|---------|--------|--------------|-------|-----------|-------------|
| **Persistence** | Git | Session | Git | Git | External |
| **Query: "What's ready?"** | Manual | Built-in | Built-in | N/A | Built-in |
| **Dependency tracking** | ASCII docs | addBlockedBy | First-class | Implicit | Built-in |
| **Parallel-safe** | No | Yes | Yes (hash IDs) | Full isolation | Yes |
| **Human-readable** | Excellent | Poor | Medium | N/A | Poor |
| **Token overhead** | High (parsing) | Low | Low (CLI) | N/A | High |
| **Setup complexity** | None | None | `bd init` | Complex | High |
| **Cross-session** | Yes | No | Yes | Yes | Yes |
| **Subagent integration** | Manual | Native | CLI/MCP | Orchestrator | Native |

---

## Recommendations

### For This Project (lustre_template_gen)

Given:
- Gleam/Lustre codebase (moderate size)
- Existing `.plan/` investment
- Need for parallel subagent support
- Preference for simplicity

**Recommended: Hybrid (.plan/ + Beads)**

1. Keep `.plan/` for epic planning and detailed specs
2. Add Beads for execution tracking
3. Link Beads issues to `.plan/` task specs via metadata
4. Use `bd ready` for subagent task discovery

**Migration Path:**
```bash
# 1. Initialize Beads
bd init

# 2. Create issues from existing .plan/ tasks
bd create "Setup project structure" -p 0 --meta spec=.plan/learning_examples/tasks/001_project_setup.md

# 3. Set up dependencies
bd dep add bd-xxx.1 bd-xxx  # Link tasks to epics
```

### For Greenfield Projects

- **Small/Medium**: Start with Native Tasks, add Beads if spanning sessions
- **Large/Enterprise**: Consider Claude-Flow or worktree isolation
- **Multi-developer**: Beads (git-native collaboration)

---

## Sources

### Beads
- [Beads GitHub](https://github.com/steveyegge/beads)
- [Introducing Beads - Steve Yegge](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a)
- [The Beads Revolution - Steve Yegge](https://steve-yegge.medium.com/the-beads-revolution-how-i-built-the-todo-system-that-ai-agents-actually-want-to-use-228a5f9be2a9)
- [Beads: Git-Friendly Issue Tracker - Better Stack](https://betterstack.com/community/guides/ai/beads-issue-tracker-ai-agents/)

### Claude Code Tasks
- [Claude Code Todos to Tasks - Rick Hightower](https://medium.com/@richardhightower/claude-code-todos-to-tasks-5a1b0e351a1c)
- [Claude Code Tasks Update - Joe Njenga](https://medium.com/@joe.njenga/claude-code-tasks-are-here-new-update-turns-claude-code-todos-to-tasks-a0be00e70847)
- [Task Agent Tools - ClaudeLog](https://claudelog.com/mechanics/task-agent-tools/)

### Multi-Agent Orchestration
- [Claude-Flow GitHub](https://github.com/ruvnet/claude-flow)
- [Multi-agent Parallel Coding - Cuong Tham](https://medium.com/@codecentrevibe/claude-code-multi-agent-parallel-coding-83271c4675fa)
- [Parallel Subagents - Tim Dietrich](https://timdietrich.me/blog/claude-code-parallel-subagents/)
- [Swarm Orchestration Skill - Kieran Klaassen](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)

### Git Worktrees
- [Git Worktrees for Parallel Agents - Medium](https://medium.com/@mabd.dev/git-worktrees-the-secret-weapon-for-running-multiple-ai-coding-agents-in-parallel-e9046451eb96)
- [Worktrees Behind Cursor's Parallel Agents - Dev.to](https://dev.to/arifszn/git-worktrees-the-power-behind-cursors-parallel-agents-19j1)
- [Agentree GitHub](https://github.com/AryaLabsHQ/agentree)

### Related Tools
- [Ralph Wiggum Technique - Awesome Claude](https://awesomeclaude.ai/ralph-wiggum)
- [Choo Choo Ralph](https://github.com/mj-meyer/choo-choo-ralph)
- [Aider](https://aider.chat/)
- [LangGraph, CrewAI, AutoGen Comparison - AI Multiple](https://research.aimultiple.com/agentic-orchestration/)

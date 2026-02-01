# Spec-Driven Development + Beads Integration

**Research Date:** 2026-02-01
**Context:** Designing a cohesive storage system for research, specs, and tasks inspired by Kiro, GitHub Spec-Kit, and Beads.

---

## Executive Summary

Combine **spec-driven development** principles (Kiro, Spec-Kit) with **Beads** execution tracking to get:
- Structured specs with EARS notation for clarity
- Machine-queryable task state for orchestration
- Single source of truth (no sync issues)
- Git-friendly storage

---

## Research: Existing Approaches

### Kiro (AWS)

Three-file spec system per feature:

```
.kiro/specs/[feature-name]/
├── requirements.md    # EARS notation user stories
├── design.md          # Architecture, diagrams, interfaces
└── tasks.md           # Implementation plan with status
```

**Strengths:**
- Clear separation of concerns (what vs how vs work)
- EARS notation reduces ambiguity
- Human-readable markdown
- Decision checkpoints between phases

**Weaknesses:**
- Files are passive (no queryable state)
- Status in tasks.md requires parsing
- No dependency graph beyond file
- Doesn't integrate with orchestration

**Source:** [Kiro Docs](https://kiro.dev/docs/specs/concepts/), [AWS Kiro Blog](https://dev.to/aws-builders/aws-kiro-agentic-coding-and-the-rise-of-spec-driven-ai-development-41h)

### GitHub Spec-Kit

Similar structure with CLI tooling:

```
.specify/
├── constitution.md    # Project principles/rules
├── spec.md            # Product requirements
├── technical-plan.md  # Architecture decisions
└── tasks/             # Generated task files
```

**Strengths:**
- CLI for scaffolding (`specify init`)
- Slash commands for workflow stages
- Agent-agnostic (works with Claude, Copilot, etc.)
- TDD-first philosophy

**Weaknesses:**
- Still file-based, not queryable
- No execution state management
- Manual task tracking

**Source:** [GitHub Spec-Kit](https://github.com/github/spec-kit), [Spec-Kit Blog](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)

### EARS Notation

Structured requirement syntax from Rolls-Royce:

```
WHEN <trigger>
THE <system> SHALL <response>

WHILE <precondition>
WHEN <trigger>
THE <system> SHALL <response>
```

**Five Patterns:**
1. **Ubiquitous** - Always true (`The system shall...`)
2. **Event-driven** - `When X, the system shall Y`
3. **State-driven** - `While X, the system shall Y`
4. **Unwanted behavior** - `If X (failure), the system shall Y`
5. **Complex** - Combination of above

**Strengths:**
- Maps directly to test cases (Given-When-Then)
- Reduces ambiguity for AI agents
- Industry-proven (NASA, Airbus, etc.)

**Source:** [EARS Intro](https://dev.to/sebastian_dingler/ears-the-easy-approach-to-requirements-syntax-39a5), [Alistair Mavin](https://alistairmavin.com/ears/)

### Beads

Database-first task tracking:

```
.beads/
├── issues.jsonl       # Git-friendly issue store
├── beads.db           # SQLite cache (not committed)
└── config.json        # Project settings
```

**Strengths:**
- Queryable (`bd ready`, `bd list --json`)
- Dependency-aware execution
- Hash-based IDs prevent conflicts
- Context-efficient (query what you need)
- Git-native (JSONL merges well)

**Weaknesses:**
- No native spec/design storage
- Task descriptions are free-form
- No structured requirement format

**Source:** [Beads GitHub](https://github.com/steveyegge/beads), [Steve Yegge Medium](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a)

---

## Analysis: The Gap

| Need | Kiro/Spec-Kit | Beads | Gap |
|------|---------------|-------|-----|
| Structured requirements | ✅ EARS | ❌ Free-form | Beads needs structure |
| Design documentation | ✅ design.md | ❌ None | Beads needs design |
| Task breakdown | ✅ tasks.md | ✅ Issues | ✓ Covered |
| Dependency tracking | ❌ Manual | ✅ First-class | ✓ Covered |
| Queryable state | ❌ Parse files | ✅ bd commands | ✓ Covered |
| Orchestration | ❌ None | ✅ Ready queue | ✓ Covered |
| Git-friendly | ✅ Markdown | ✅ JSONL | ✓ Both work |

**Key insight:** Kiro excels at **specification**, Beads excels at **execution**. We need both.

---

## Proposed Solution: Beads with Spec Structure

### Design Principles

1. **Beads is the single source of truth** - No separate files to sync
2. **Specs are structured data, not free text** - Use consistent fields
3. **EARS notation for requirements** - Machine-parseable, testable
4. **Hierarchical organization** - Epic → Requirements → Design → Tasks
5. **Everything queryable** - `bd` commands for all artifacts

### Proposed Structure

```
.beads/
├── issues.jsonl       # All artifacts stored here
├── beads.db           # Local cache
└── config.json

# Issue types (via labels or conventions):
# - epic        : High-level feature/initiative
# - requirement : EARS-formatted requirement
# - design      : Technical design decisions
# - task        : Implementation work item
# - research    : Research/investigation notes
```

### Issue Type: Epic

```json
{
  "id": "lt-a1b2",
  "type": "epic",
  "subject": "Parallel Orchestrator",
  "description": "Implement parallel agent orchestration using Beads + worktrees",
  "status": "open",
  "priority": 0,
  "labels": ["epic"],
  "meta": {
    "goal": "Enable multiple AI agents to work on tasks concurrently",
    "scope_in": ["beads integration", "worktrees", "pr workflow"],
    "scope_out": ["web ui", "cloud deployment"],
    "success_criteria": [
      "Agents can work in parallel without conflicts",
      "System recovers from crashes",
      "PRs auto-merged when CI passes"
    ]
  }
}
```

### Issue Type: Requirement

```json
{
  "id": "lt-a1b2.r1",
  "type": "requirement",
  "subject": "Task state queryable via CLI",
  "description": "WHEN an agent needs task state\nTHE orchestrator SHALL query Beads\nAND return only relevant tasks",
  "status": "approved",
  "priority": 1,
  "labels": ["requirement", "ears:event-driven"],
  "parent": "lt-a1b2",
  "meta": {
    "ears_pattern": "event-driven",
    "acceptance_criteria": [
      "bd ready returns unblocked tasks",
      "bd list --json returns full state",
      "Response time < 100ms"
    ],
    "user_story": "As an orchestrator, I want to query task state so that I can assign work to agents"
  }
}
```

### Issue Type: Design

```json
{
  "id": "lt-a1b2.d1",
  "type": "design",
  "subject": "State reconstruction architecture",
  "description": "## Overview\nOrchestrator reconstructs state from Beads on each cycle.\n\n## Components\n- Beads CLI for queries\n- Metadata for phase tracking\n- PID tracking for crash detection\n\n## Data Flow\n```\nbd ready → filter by epic → spawn agents → update meta\n```",
  "status": "approved",
  "priority": 1,
  "labels": ["design"],
  "parent": "lt-a1b2",
  "meta": {
    "components": ["orchestrator", "beads", "worktrees"],
    "decisions": [
      {"decision": "Use Beads metadata for state", "rationale": "Single source of truth"},
      {"decision": "Stateless orchestrator", "rationale": "Crash resilience"}
    ],
    "interfaces": {
      "beads_meta": ["worktree", "branch", "agent_pid", "phase", "pr_number"]
    }
  }
}
```

### Issue Type: Task

```json
{
  "id": "lt-a1b2.1",
  "type": "task",
  "subject": "Initialize Beads in project",
  "description": "Set up Beads as task management system",
  "status": "open",
  "priority": 1,
  "labels": ["task"],
  "parent": "lt-a1b2",
  "blocked_by": [],
  "meta": {
    "implements": ["lt-a1b2.r1"],
    "spec": {
      "steps": [
        "Verify bd CLI installed",
        "Run bd init",
        "Configure .beads/config.json",
        "Update .gitignore"
      ],
      "acceptance": [
        "bd list returns empty (no errors)",
        "bd --version >= 0.20.1"
      ],
      "files_to_modify": [".beads/config.json", ".gitignore"]
    }
  }
}
```

### Issue Type: Research

```json
{
  "id": "lt-a1b2.res1",
  "type": "research",
  "subject": "Task management alternatives analysis",
  "description": "Research Beads, Kiro, Spec-Kit, worktrees for parallel agent support",
  "status": "closed",
  "priority": 2,
  "labels": ["research"],
  "parent": "lt-a1b2",
  "meta": {
    "findings": "Beads for execution, Kiro-style specs for structure",
    "recommendation": "Hybrid approach with Beads as execution layer",
    "artifacts": [".plan/research/task_management_alternatives.md"]
  }
}
```

---

## Workflow: Spec-Driven with Beads

### Phase 1: Requirements

```bash
# Create epic
bd create "Epic: Feature Name" -p 0 --label epic

# Add requirements with EARS notation
bd create "WHEN user logs in THE system SHALL create session" \
  -p 1 --label requirement --label ears:event-driven \
  --parent lt-a1b2

# Review requirements
bd list --label requirement --parent lt-a1b2
```

### Phase 2: Design

```bash
# Create design document
bd create "Authentication architecture" \
  -p 1 --label design --parent lt-a1b2

# Add design details via comment (supports markdown)
bd comment lt-a1b2.d1 "
## Components
- AuthService: JWT generation/validation
- SessionStore: Redis-backed session cache

## Sequence
1. User submits credentials
2. AuthService validates
3. JWT token returned
4. Session created in store
"
```

### Phase 3: Tasks

```bash
# Create tasks that implement requirements
bd create "Implement AuthService" \
  -p 1 --label task --parent lt-a1b2 \
  --meta implements=lt-a1b2.r1

# Set dependencies
bd dep add lt-a1b2.2 lt-a1b2.1  # Task 2 blocked by Task 1

# Add task spec
bd comment lt-a1b2.1 "
## Steps
1. Create src/auth/service.gleam
2. Implement validate_credentials/2
3. Implement generate_token/1

## Tests
- Valid credentials return token
- Invalid credentials return error
"
```

### Phase 4: Execution

```bash
# Query ready work
bd ready --label task --parent lt-a1b2

# Run orchestrator
just orchestrate --epic lt-a1b2

# Track progress
bd list --parent lt-a1b2 --json | jq 'group_by(.labels[]) | map({label: .[0].labels[0], count: length})'
```

---

## CLI Extensions Needed

To fully support this, Beads would benefit from:

```bash
# Filter by type/label
bd list --label requirement
bd list --type epic

# View hierarchy
bd tree lt-a1b2              # Show epic with all children

# EARS validation (optional)
bd lint --ears lt-a1b2.r1    # Validate EARS format

# Spec export (for human review)
bd export --format spec lt-a1b2 > feature-spec.md
```

These could be implemented as:
1. Shell aliases/functions wrapping `bd` + `jq`
2. Custom beads plugin
3. Justfile commands

---

## Justfile Integration

```makefile
# Create new epic with structure
new-epic name:
    #!/bin/bash
    epic_id=$(bd create "Epic: {{name}}" -p 0 --label epic --json | jq -r '.id')
    echo "Created epic: $epic_id"
    echo "Next steps:"
    echo "  bd create 'WHEN x THE system SHALL y' -p 1 --label requirement --parent $epic_id"

# Add requirement (EARS)
add-req epic pattern:
    bd create "{{pattern}}" -p 1 --label requirement --parent {{epic}}

# Add design
add-design epic title:
    bd create "{{title}}" -p 1 --label design --parent {{epic}}

# Add task
add-task epic title:
    bd create "{{title}}" -p 1 --label task --parent {{epic}}

# View epic spec
view-spec epic:
    #!/bin/bash
    echo "# Epic: $(bd show {{epic}} --json | jq -r '.subject')"
    echo ""
    echo "## Requirements"
    bd list --json | jq -r '.issues[] | select(.labels[]? == "requirement") | select(.parent == "{{epic}}") | "- [\(.status)] \(.subject)"'
    echo ""
    echo "## Design"
    bd list --json | jq -r '.issues[] | select(.labels[]? == "design") | select(.parent == "{{epic}}") | "### \(.subject)\n\(.description)\n"'
    echo ""
    echo "## Tasks"
    bd list --json | jq -r '.issues[] | select(.labels[]? == "task") | select(.parent == "{{epic}}") | "- [\(.status)] \(.id): \(.subject)"'
```

---

## Migration Path

### From Current .plan/ Structure

```bash
# 1. Create epic in Beads
epic_id=$(bd create "Epic: Parallel Orchestrator" -p 0 --label epic --json | jq -r '.id')

# 2. Import PLAN.md goals as epic metadata
bd update $epic_id --meta goal="..." --meta scope_in="..."

# 3. Create requirements from success criteria
bd create "WHEN agent crashes THE orchestrator SHALL detect and respawn" \
  -p 1 --label requirement --parent $epic_id

# 4. Create design from PLAN.md architecture
bd create "Stateless orchestrator architecture" \
  -p 1 --label design --parent $epic_id
bd comment $design_id "$(cat .plan/parallel_orchestrator/PLAN.md | sed -n '/## Design/,/## Task/p')"

# 5. Import tasks (already covered in task 008)

# 6. Archive .plan/ (task 009)
```

---

## Comparison: Before vs After

| Aspect | Before (.plan/) | After (Beads) |
|--------|-----------------|---------------|
| Requirements | In PLAN.md prose | Structured EARS issues |
| Design | In PLAN.md section | Dedicated design issues |
| Tasks | Separate .md files | Beads issues with specs in comments |
| Status | README.md checkboxes | `bd list --status` |
| Dependencies | ASCII graph | `bd dep tree` |
| Queries | grep/manual | `bd list --label X --parent Y` |
| Research | Separate folder | Research issues linked to epic |

---

## Recommendations

### Immediate (Update Epic)

1. Use hybrid approach: `.specs/` for discovery, `.beads/` for execution
2. Task descriptions use EARS format for disambiguation
3. Add justfile commands for spec workflow

### Hybrid Structure (Revised)

```
.specs/                              # Discoverable via Glob/Grep/Read
├── <feature>/
│   ├── README.md                    # Overview
│   ├── requirements.md              # EARS requirements
│   ├── design.md                    # Architecture
│   └── research/                    # Investigation notes

.beads/                              # Queryable execution state
└── issues.jsonl                     # Tasks link to specs via meta.spec_file
```

**Rationale:** Agents naturally explore filesystems with Glob/Grep/Read. Pure Beads requires knowing to query. Hybrid gives both discovery and queryable state.

### Future (Beads Enhancements)

1. Propose EARS linting to Beads project
2. Propose `--type` filter as alias for `--label`
3. Propose `bd tree` command for hierarchy view
4. Consider Beads plugin for spec export

---

## Sources

- [Kiro Docs - Specs Concepts](https://kiro.dev/docs/specs/concepts/)
- [Kiro - Spec-Driven Development](https://kiro.dev/blog/kiro-and-the-future-of-software-development/)
- [GitHub Spec-Kit](https://github.com/github/spec-kit)
- [GitHub Blog - Spec-Driven Development](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- [EARS Notation - Alistair Mavin](https://alistairmavin.com/ears/)
- [EARS Dev.to Guide](https://dev.to/sebastian_dingler/ears-the-easy-approach-to-requirements-syntax-39a5)
- [Beads GitHub](https://github.com/steveyegge/beads)
- [Beads - Better Stack Guide](https://betterstack.com/community/guides/ai/beads-issue-tracker-ai-agents/)

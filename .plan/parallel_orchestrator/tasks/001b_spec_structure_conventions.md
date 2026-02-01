# Task 001b: Spec Structure Conventions

## Description

WHEN the project needs discoverable specs AND queryable execution state
THE system SHALL use a hybrid approach with `.specs/` for markdown documentation AND `.beads/` for task tracking
AND link them via `meta.spec_file` metadata

## Dependencies

- 001_initialize_beads - Beads must be initialized first

## Implements

- REQ-006: Spec Discovery
- REQ-007: State Single Source

## Success Criteria

1. WHEN an agent runs `Grep "topic" .specs/` THEN relevant specs are discoverable
2. WHEN a task is created in Beads THEN it links to its spec via `meta.spec_file`
3. WHEN `just new-spec <name>` is run THEN a complete spec folder is created
4. WHEN `just view-spec <epic>` is run THEN the spec and task status are displayed

## Implementation Steps

### 1. Create .specs/ Directory Structure

```bash
mkdir -p .specs/_templates
```

Create `.specs/_templates/README.md`:
```markdown
# [Feature Name]

## Overview
[Brief description of what this feature does]

## Requirements
See `requirements.md` for EARS-formatted requirements.

## Design
See `design.md` for architecture and technical decisions.

## Research
See `research/` for investigation notes and alternatives analysis.

## Related Tasks
Query with: `bd list --json | jq '.issues[] | select(.meta.spec_dir == ".specs/[feature]")'`
```

Create `.specs/_templates/requirements.md`:
```markdown
# Requirements

Requirements use EARS (Easy Approach to Requirements Syntax).

## Patterns
- **Event-driven**: WHEN <trigger> THE <system> SHALL <response>
- **State-driven**: WHILE <condition> THE <system> SHALL <response>
- **Complex**: WHILE <condition> WHEN <trigger> THE <system> SHALL <response>

---

## REQ-001: [Requirement Name]

WHEN [trigger event]
THE [system component] SHALL [expected behavior]
AND [additional behavior if any]

**Acceptance Criteria:**
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]

---

## REQ-002: [Requirement Name]

[Continue pattern...]
```

Create `.specs/_templates/design.md`:
```markdown
# Design

## Overview
[High-level architecture description]

## Components
[List and describe main components]

## Data Flow
```
[ASCII diagram or description]
```

## Interfaces
[API contracts, data structures]

## Decisions
| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| [Choice] | [Why] | [What else was considered] |

## Error Handling
[How errors are handled]
```

### 2. Create Justfile Commands

Add to `justfile`:

```makefile
# ==============================================================================
# Spec-Driven Development
# ==============================================================================

# Create new spec folder from template
new-spec name:
    #!/bin/bash
    if [ -d ".specs/{{name}}" ]; then
        echo "Spec already exists: .specs/{{name}}"
        exit 1
    fi
    mkdir -p ".specs/{{name}}/research"
    cp .specs/_templates/README.md ".specs/{{name}}/"
    cp .specs/_templates/requirements.md ".specs/{{name}}/"
    cp .specs/_templates/design.md ".specs/{{name}}/"
    sed -i '' 's/\[Feature Name\]/{{name}}/g' ".specs/{{name}}/README.md" 2>/dev/null || \
        sed -i 's/\[Feature Name\]/{{name}}/g' ".specs/{{name}}/README.md"
    echo "Created .specs/{{name}}/"
    echo ""
    echo "Next steps:"
    echo "  1. Edit .specs/{{name}}/requirements.md with EARS requirements"
    echo "  2. Edit .specs/{{name}}/design.md with architecture"
    echo "  3. Run: just new-epic {{name}}"

# Create epic in Beads linked to spec folder
new-epic name:
    #!/bin/bash
    spec_dir=".specs/{{name}}"
    if [ ! -d "$spec_dir" ]; then
        echo "Spec folder not found. Create it first:"
        echo "  just new-spec {{name}}"
        exit 1
    fi
    epic_id=$(bd create "Epic: {{name}}" -p 0 --label epic \
        --meta spec_dir="$spec_dir" --json | jq -r '.id')
    echo "Created epic: $epic_id"
    echo "Linked to: $spec_dir"
    echo ""
    echo "Add tasks with:"
    echo "  just new-task $epic_id 'Task description' REQ-001"

# Create task linked to requirement
new-task epic title req="":
    #!/bin/bash
    spec_dir=$(bd show {{epic}} --json | jq -r '.meta.spec_dir // empty')
    task_id=$(bd create "{{title}}" -p 1 --label task --parent {{epic}} \
        --meta spec_file="${spec_dir}/requirements.md" \
        --meta implements="{{req}}" --json | jq -r '.id')
    echo "Created task: $task_id"
    [ -n "{{req}}" ] && echo "Implements: {{req}}"
    echo ""
    echo "Add details with: bd comment $task_id 'implementation steps...'"

# Add research document
new-research epic title:
    #!/bin/bash
    spec_dir=$(bd show {{epic}} --json | jq -r '.meta.spec_dir // empty')
    if [ -z "$spec_dir" ]; then
        echo "Epic has no spec_dir. Create spec first."
        exit 1
    fi
    filename=$(echo "{{title}}" | tr '[:upper:] ' '[:lower:]_' | tr -cd '[:alnum:]_').md
    filepath="$spec_dir/research/$filename"
    cat > "$filepath" << 'EOF'
# {{title}}

**Date:** $(date +%Y-%m-%d)
**Status:** In Progress

## Question
[What are we trying to find out?]

## Findings
[What did we discover?]

## Recommendation
[What do we suggest based on findings?]

## Sources
- [Links to references]
EOF
    echo "Created: $filepath"
    # Also create Beads issue for tracking
    bd create "Research: {{title}}" -p 2 --label research --parent {{epic}} \
        --meta spec_file="$filepath"

# View spec with related tasks
view-spec epic:
    #!/bin/bash
    spec_dir=$(bd show {{epic}} --json | jq -r '.meta.spec_dir // empty')
    echo "# $(bd show {{epic}} --json | jq -r '.subject')"
    echo ""
    if [ -n "$spec_dir" ] && [ -d "$spec_dir" ]; then
        echo "## Spec Location: $spec_dir"
        echo ""
        if [ -f "$spec_dir/README.md" ]; then
            head -20 "$spec_dir/README.md"
            echo "..."
        fi
    fi
    echo ""
    echo "## Requirements"
    if [ -f "$spec_dir/requirements.md" ]; then
        grep -E "^## REQ-" "$spec_dir/requirements.md" 2>/dev/null || echo "(none defined)"
    fi
    echo ""
    echo "## Tasks"
    bd list --json | jq -r --arg epic "{{epic}}" \
        '.issues[] | select(.parent == $epic) | select(.labels[]? == "task") | "- [\(.status)] \(.id): \(.subject) (implements: \(.meta.implements // "n/a"))"' \
        2>/dev/null || echo "(none)"
    echo ""
    echo "## Research"
    bd list --json | jq -r --arg epic "{{epic}}" \
        '.issues[] | select(.parent == $epic) | select(.labels[]? == "research") | "- [\(.status)] \(.subject)"' \
        2>/dev/null || echo "(none)"

# Find specs mentioning a topic
find-specs topic:
    @echo "Searching .specs/ for: {{topic}}"
    @grep -r "{{topic}}" .specs/ --include="*.md" -l 2>/dev/null || echo "No matches found"

# List all epics with their spec locations
list-epics:
    @bd list --json | jq -r '.issues[] | select(.labels[]? == "epic") | "\(.id)\t\(.meta.spec_dir // "no spec")\t\(.subject)"'
```

### 3. Create EARS Convention Document

Create `.specs/CONVENTIONS.md`:

```markdown
# Spec Conventions

## Directory Structure

Each feature has its own spec folder:

```
.specs/
├── _templates/              # Templates for new specs
│   ├── README.md
│   ├── requirements.md
│   └── design.md
├── <feature>/
│   ├── README.md            # Overview and navigation
│   ├── requirements.md      # EARS requirements
│   ├── design.md            # Architecture
│   └── research/            # Investigation notes
│       └── *.md
└── CONVENTIONS.md           # This file
```

## EARS Requirements Syntax

Requirements use EARS (Easy Approach to Requirements Syntax) for clarity:

### Event-Driven (most common)
```
WHEN <trigger event>
THE <system component> SHALL <expected behavior>
```

Example:
```
WHEN a user submits invalid credentials
THE auth service SHALL return a 401 error
AND log the failed attempt
```

### State-Driven
```
WHILE <system is in state>
THE <system component> SHALL <maintain behavior>
```

Example:
```
WHILE the rate limit is exceeded
THE API SHALL reject requests with 429 status
```

### Complex (state + event)
```
WHILE <precondition>
WHEN <trigger event>
THE <system component> SHALL <expected behavior>
```

Example:
```
WHILE CI checks are passing
WHEN PR has no merge conflicts
THE merger agent SHALL auto-merge the PR
```

## Linking Specs to Beads

### Epic links to spec folder:
```bash
bd create "Epic: Feature" --meta spec_dir=".specs/feature"
```

### Task links to requirement:
```bash
bd create "Implement X" --meta spec_file=".specs/feature/requirements.md" --meta implements="REQ-001"
```

### Query tasks by spec:
```bash
bd list --json | jq '.issues[] | select(.meta.spec_file | contains("feature"))'
```

## Workflow

1. `just new-spec feature-name` - Create spec folder
2. Edit requirements.md with EARS requirements
3. Edit design.md with architecture
4. `just new-epic feature-name` - Create linked epic in Beads
5. `just new-task <epic> "Task" REQ-001` - Create tasks implementing requirements
```

### 4. Initialize for This Epic

Create the spec folder for parallel_orchestrator:

```bash
# This epic's specs (already in .plan/research/, will migrate in task 008)
mkdir -p .specs/parallel_orchestrator/research
# Link research files or migrate them
```

## Test Cases

### Test 1: Spec Discovery
```bash
#!/bin/bash
# Create test spec
just new-spec test-feature
[ -f ".specs/test-feature/requirements.md" ] || exit 1

# Search should find it
just find-specs "EARS" | grep -q "test-feature" || exit 1

# Cleanup
rm -rf .specs/test-feature
echo "PASS: spec discovery works"
```

### Test 2: Epic-Spec Linking
```bash
#!/bin/bash
# Create spec and epic
just new-spec test-link
epic_id=$(bd create "Epic: test-link" -p 0 --label epic --meta spec_dir=".specs/test-link" --json | jq -r '.id')

# Verify link
spec_dir=$(bd show $epic_id --json | jq -r '.meta.spec_dir')
[ "$spec_dir" = ".specs/test-link" ] || exit 1

# Cleanup
bd delete $epic_id --force
rm -rf .specs/test-link
echo "PASS: epic-spec linking works"
```

### Test 3: EARS Format in Requirements
```bash
#!/bin/bash
# Verify template has EARS format
grep -q "WHEN.*THE.*SHALL" .specs/_templates/requirements.md || exit 1
echo "PASS: EARS format in templates"
```

## Verification Checklist

- [ ] `.specs/_templates/` created with README.md, requirements.md, design.md
- [ ] `.specs/CONVENTIONS.md` created with EARS documentation
- [ ] Justfile commands added: new-spec, new-epic, new-task, new-research, view-spec, find-specs, list-epics
- [ ] `just new-spec test && just new-epic test` workflow works
- [ ] Specs discoverable via `Grep "topic" .specs/`
- [ ] Tasks link to specs via `meta.spec_file`

## Notes

- EARS is a guideline for clarity, not enforced programmatically
- Agents can discover specs naturally via Glob/Grep
- Beads remains source of truth for execution state
- This replaces `.plan/` folder entirely after migration

## Files to Create/Modify

- `.specs/_templates/README.md` - Create
- `.specs/_templates/requirements.md` - Create
- `.specs/_templates/design.md` - Create
- `.specs/CONVENTIONS.md` - Create
- `justfile` - Add spec-driven commands

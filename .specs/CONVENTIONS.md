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

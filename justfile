# ghtml - Gleam HTML Template Generator - Development Commands
# Run `just` to see available commands
# Any unknown command falls through to gleam: `just add package` → `gleam add package`

# Default: show help
default:
    @just --list

# === Workflows ===

# Run all quality checks (build → unit → integration → e2e → examples → format → docs)
check:
    gleam build
    just unit
    just integration
    just e2e
    just check-examples
    gleam format
    gleam docs build
    @echo "✓ All checks passed"

# Simulate CI pipeline (matches .github/workflows/test.yml)
ci:
    gleam build
    just unit
    just integration
    just e2e
    just check-examples
    gleam format --check src test
    gleam docs build
    @echo "✓ CI simulation passed"

# === CLI Execution ===

# Run the CLI (default mode)
run:
    gleam run -m ghtml

# Run with force regeneration
run-force:
    gleam run -m ghtml -- force

# Run in watch mode
run-watch:
    gleam run -m ghtml -- watch

# Run orphan cleanup only
run-clean:
    gleam run -m ghtml -- clean

# === Examples ===

# Validate all examples build successfully (used by check/ci)
check-examples:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Validating examples..."
    # First, generate .gleam files from .ghtml templates
    gleam run -m ghtml -- examples
    # Then build each example
    for dir in examples/*/; do
        if [ -f "$dir/gleam.toml" ]; then
            name=$(basename "$dir")
            echo "  Building examples/$name..."
            (cd "$dir" && gleam deps download && gleam build) || {
                echo "✗ Example failed: examples/$name"
                exit 1
            }
        fi
    done
    echo "✓ All examples build successfully"

# Build all examples (runs codegen and gleam build for each)
examples:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in examples/*/; do
        if [ -f "$dir/justfile" ]; then
            echo "Building example: $dir"
            (cd "$dir" && just build)
        fi
    done
    echo "✓ All examples built"

# Clean all examples (removes build artifacts and generated files)
examples-clean:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in examples/*/; do
        if [ -f "$dir/justfile" ]; then
            echo "Cleaning example: $dir"
            (cd "$dir" && just clean)
        fi
    done
    echo "✓ All examples cleaned"

# === Spec-Driven Development ===

# Create new spec folder from template
new-spec name:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d ".claude/specs/{{name}}" ]; then
        echo "Spec already exists: .claude/specs/{{name}}"
        exit 1
    fi
    mkdir -p ".claude/specs/{{name}}/research"
    cp .claude/specs/_templates/README.md ".claude/specs/{{name}}/"
    cp .claude/specs/_templates/requirements.md ".claude/specs/{{name}}/"
    cp .claude/specs/_templates/design.md ".claude/specs/{{name}}/"
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' 's/\[Feature Name\]/{{name}}/g' ".claude/specs/{{name}}/README.md"
    else
        sed -i 's/\[Feature Name\]/{{name}}/g' ".claude/specs/{{name}}/README.md"
    fi
    echo "Created .claude/specs/{{name}}/"
    echo ""
    echo "Next steps:"
    echo "  1. Edit .claude/specs/{{name}}/requirements.md with EARS requirements"
    echo "  2. Edit .claude/specs/{{name}}/design.md with architecture"
    echo "  3. Run: just new-epic {{name}}"

# Create epic in Beads linked to spec folder
new-epic name:
    #!/usr/bin/env bash
    set -euo pipefail
    spec_dir=".claude/specs/{{name}}"
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
    #!/usr/bin/env bash
    set -euo pipefail
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
    #!/usr/bin/env bash
    set -euo pipefail
    spec_dir=$(bd show {{epic}} --json | jq -r '.meta.spec_dir // empty')
    if [ -z "$spec_dir" ]; then
        echo "Epic has no spec_dir. Create spec first."
        exit 1
    fi
    filename=$(echo "{{title}}" | tr '[:upper:] ' '[:lower:]_' | tr -cd '[:alnum:]_').md
    filepath="$spec_dir/research/$filename"
    today=$(date +%Y-%m-%d)
    printf '%s\n' "# {{title}}" "" "**Date:** $today" "**Status:** In Progress" "" "## Question" "[What are we trying to find out?]" "" "## Findings" "[What did we discover?]" "" "## Recommendation" "[What do we suggest based on findings?]" "" "## Sources" "- [Links to references]" > "$filepath"
    echo "Created: $filepath"
    bd create "Research: {{title}}" -p 2 --label research --parent {{epic}} \
        --meta spec_file="$filepath"

# View spec with related tasks
view-spec epic:
    #!/usr/bin/env bash
    set -euo pipefail
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
        '.[] | select(.parent == $epic) | select(.labels[]? == "task") | "- [\(.status)] \(.id): \(.subject) (implements: \(.meta.implements // "n/a"))"' \
        2>/dev/null || echo "(none)"
    echo ""
    echo "## Research"
    bd list --json | jq -r --arg epic "{{epic}}" \
        '.[] | select(.parent == $epic) | select(.labels[]? == "research") | "- [\(.status)] \(.subject)"' \
        2>/dev/null || echo "(none)"

# Find specs mentioning a topic
find-specs topic:
    @echo "Searching .claude/specs/ for: {{topic}}"
    @grep -r "{{topic}}" .claude/specs/ --include="*.md" -l 2>/dev/null || echo "No matches found"

# List all epics with their spec locations
list-epics:
    @bd list --json | jq -r '.[] | select(.labels[]? == "epic") | "\(.id)\t\(.meta.spec_dir // "no spec")\t\(.subject)"'

# === Orchestration ===

# Run parallel agent orchestrator
orchestrate *args:
    ./scripts/orchestrate.sh {{args}}

# Run orchestrator for a specific epic
orchestrate-epic epic max_agents="4":
    ./scripts/orchestrate.sh --epic {{epic}} --max-agents {{max_agents}}

# Preview orchestration without executing
orchestrate-preview *args:
    ./scripts/orchestrate.sh --dry-run {{args}}

# Show orchestration status from beads
orchestrate-status:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Ready Tasks ==="
    bd ready 2>/dev/null || echo "No ready tasks"
    echo ""
    echo "=== In Progress ==="
    bd list --status in_progress 2>/dev/null || echo "None in progress"
    echo ""
    echo "=== Active Worktrees ==="
    git worktree list | grep -v "$(pwd)" || echo "No worktrees"
    echo ""
    echo "=== Open Agent PRs ==="
    gh pr list --json number,title,headRefName \
        --jq '.[] | select(.headRefName | startswith("agent/")) | "#\(.number): \(.title)"' \
        2>/dev/null || echo "No agent PRs"

# Spawn a single worker agent for a task
worker task_id:
    ./scripts/run-worker.sh {{task_id}}

# Run the merger agent to process PRs
merger *args:
    ./scripts/run-merger.sh {{args}}

# Clean up all worktrees
worktree-clean:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Removing worktrees..."
    git worktree list --porcelain | grep "worktree" | cut -d' ' -f2 | \
        grep -v "$(pwd)" | xargs -I{} git worktree remove {} --force 2>/dev/null || true
    git worktree prune
    echo "Done"

# Remove a specific worktree
worktree-remove task_id:
    git worktree remove "../worktrees/{{task_id}}" --force 2>/dev/null || true
    git branch -d "agent/{{task_id}}" 2>/dev/null || true

# Show orchestration help
orchestrate-help:
    @echo "Parallel Orchestration Commands:"
    @echo ""
    @echo "  just orchestrate              Run orchestrator for all ready tasks"
    @echo "  just orchestrate --epic X     Run for specific epic"
    @echo "  just orchestrate-epic X       Shorthand for --epic"
    @echo "  just orchestrate-status       Show current orchestration state"
    @echo "  just orchestrate-preview      Preview what would run (dry-run)"
    @echo ""
    @echo "  just worker <task-id>         Spawn single worker agent"
    @echo "  just merger                   Run merger to process PRs"
    @echo "  just merger --dry-run         Preview merger actions"
    @echo ""
    @echo "  just worktree-clean           Remove all worktrees"
    @echo "  just worktree-remove <id>     Remove specific worktree"
    @echo ""
    @echo "  just test-crash-recovery      Run crash recovery tests"

# Run crash recovery tests
test-crash-recovery:
    ./scripts/test-crash-recovery.sh

# === Planning ===

# Create a new epic from template (e.g., just epic my_feature)
epic name:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d ".claude/plan/{{name}}" ]; then
        echo "Error: Epic '.claude/plan/{{name}}' already exists"
        exit 1
    fi
    cp -r .claude/plan/_template ".claude/plan/{{name}}"
    echo "✓ Created epic: .claude/plan/{{name}}/"
    echo "  - Edit .claude/plan/{{name}}/PLAN.md with your epic details"
    echo "  - Create tasks from .claude/plan/{{name}}/tasks/000_template_task.md"

# === Testing ===

# Run all unit tests (fast)
unit:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running unit tests..."
    gleam build
    # Find all unit test modules and run them via EUnit
    MODULES=$(find test/unit -name "*_test.gleam" | sed 's|test/||' | sed 's|\.gleam$||' | sed 's|/|@|g' | tr '\n' ' ')
    erl -pa build/dev/erlang/*/ebin -noshell -eval "
        Modules = [list_to_atom(M) || M <- string:tokens(\"$MODULES\", \" \")],
        case eunit:test(Modules, [verbose]) of
            ok -> erlang:halt(0);
            _ -> erlang:halt(1)
        end.
    "
    echo "✓ Unit tests passed"

# Run Gleam integration tests
integration:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running integration tests..."
    gleam build
    # Find all integration test modules and run them via EUnit
    MODULES=$(find test/integration -name "*_test.gleam" | sed 's|test/||' | sed 's|\.gleam$||' | sed 's|/|@|g' | tr '\n' ' ')
    erl -pa build/dev/erlang/*/ebin -noshell -eval "
        Modules = [list_to_atom(M) || M <- string:tokens(\"$MODULES\", \" \")],
        case eunit:test(Modules, [verbose]) of
            ok -> erlang:halt(0);
            _ -> erlang:halt(1)
        end.
    "
    echo "✓ Integration tests passed"

# Run all tests
test: unit integration
    @echo "✓ All tests passed"

# === E2E Testing ===

# Run all E2E tests (slow - build verification + SSR)
e2e:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Regenerating SSR test modules..."
    just e2e-regen
    echo "Running E2E tests..."
    gleam build
    # Find all e2e test modules and run them via EUnit
    MODULES=$(find test/e2e -name "*_test.gleam" | sed 's|test/||' | sed 's|\.gleam$||' | sed 's|/|@|g' | tr '\n' ' ')
    erl -pa build/dev/erlang/*/ebin -noshell -eval "
        Modules = [list_to_atom(M) || M <- string:tokens(\"$MODULES\", \" \")],
        case eunit:test(Modules, [verbose]) of
            ok -> erlang:halt(0);
            _ -> erlang:halt(1)
        end.
    "
    echo "✓ E2E tests passed"

# Run only build verification tests
e2e-build:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running build verification tests..."
    gleam test --target erlang -- --module build_test
    echo "✓ Build verification tests passed"

# Run only SSR HTML tests
e2e-ssr:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running SSR tests..."
    gleam test --target erlang -- --module ssr_test
    echo "✓ SSR tests passed"

# Regenerate E2E SSR test modules from fixtures
e2e-regen:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Regenerating SSR test modules..."

    # Build first to ensure codegen is compiled
    gleam build

    # Generate each fixture using the template generator
    # The output goes to test/e2e/generated/ with proper module names
    for fixture in test/fixtures/simple/basic.ghtml \
                   test/fixtures/attributes/all_attrs.ghtml \
                   test/fixtures/control_flow/full.ghtml \
                   test/fixtures/fragments/multiple_roots.ghtml \
                   test/fixtures/custom_elements/web_components.ghtml \
                   test/fixtures/edge_cases/special.ghtml; do
        echo "  Processing: $fixture"
        # The generator outputs alongside source, so we need to process after
    done

    # Run generator on fixtures dir (creates .gleam files alongside .ghtml)
    gleam run -m ghtml -- test/fixtures

    # Copy to e2e/generated with appropriate names
    mkdir -p test/e2e/generated
    cp test/fixtures/simple/basic.gleam test/e2e/generated/basic.gleam 2>/dev/null || true
    cp test/fixtures/attributes/all_attrs.gleam test/e2e/generated/attributes.gleam 2>/dev/null || true
    cp test/fixtures/control_flow/full.gleam test/e2e/generated/control_flow.gleam 2>/dev/null || true
    cp test/fixtures/fragments/multiple_roots.gleam test/e2e/generated/fragments.gleam 2>/dev/null || true
    cp test/fixtures/custom_elements/web_components.gleam test/e2e/generated/custom_elements.gleam 2>/dev/null || true
    cp test/fixtures/edge_cases/special.gleam test/e2e/generated/edge_cases.gleam 2>/dev/null || true

    # Clean up generated files from fixtures directory
    rm -f test/fixtures/simple/basic.gleam
    rm -f test/fixtures/attributes/all_attrs.gleam
    rm -f test/fixtures/control_flow/full.gleam
    rm -f test/fixtures/fragments/multiple_roots.gleam
    rm -f test/fixtures/custom_elements/web_components.gleam
    rm -f test/fixtures/edge_cases/special.gleam

    # Fix import paths for generated modules (types -> e2e/generated/types)
    # Use platform-specific sed syntax (macOS vs Linux)
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' 's/^import types\./import e2e\/generated\/types./' test/e2e/generated/control_flow.gleam
    else
        sed -i 's/^import types\./import e2e\/generated\/types./' test/e2e/generated/control_flow.gleam
    fi

    # Format the generated files
    gleam format test/e2e/generated/

    echo "Generated SSR test modules:"
    ls -la test/e2e/generated/*.gleam
    echo "✓ SSR test modules regenerated"

# === GIF Recording ===

# Regenerate all README GIFs (requires: brew install asciinema agg tmux bat ffmpeg)
gifs:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Regenerating all GIFs..."
    for script in assets/gif-record/record-*.sh; do
        name=$(basename "$script" .sh | sed 's/record-//')
        echo "  Recording: $name"
        bash "$script"
    done
    echo "✓ All GIFs regenerated in assets/gifs/"

# Record a single GIF (e.g., just gif hero)
gif name:
    #!/usr/bin/env bash
    set -euo pipefail
    script="assets/gif-record/record-{{name}}.sh"
    if [ ! -f "$script" ]; then
        echo "Error: Script '$script' not found"
        echo "Available: $(ls assets/gif-record/record-*.sh | xargs -n1 basename | sed 's/record-//' | sed 's/.sh//' | tr '\n' ' ')"
        exit 1
    fi
    echo "Recording: {{name}}"
    bash "$script"
    echo "✓ Created assets/gifs/{{name}}.gif"

# === Utilities ===

# Clean build artifacts
clean:
    rm -rf build

# Run a specific test file (e.g., just test-file tokenizer)
test-file name:
    gleam test -- --only {{name}}

# === Gleam Passthrough ===

# Pass any other command to gleam (e.g., just add package → gleam add package)
[positional-arguments]
@g *args:
    gleam {{args}}

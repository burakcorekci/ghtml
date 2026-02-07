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
    # Use label to link epic to spec folder (spec:<name>)
    epic_id=$(bd create "Epic: {{name}}" -p 0 --label epic --label "spec:{{name}}" \
        --notes "Spec: $spec_dir" --json | jq -r '.id')
    echo "Created epic: $epic_id"
    echo "Spec folder: $spec_dir"
    echo ""
    echo "Add tasks with:"
    echo "  just new-task $epic_id 'Task description'"

# Create task under epic
new-task epic title:
    #!/usr/bin/env bash
    set -euo pipefail
    task_id=$(bd create "{{title}}" -p 1 --label task --parent {{epic}} --json | jq -r '.id')
    echo "Created task: $task_id (parent: {{epic}})"
    echo ""
    echo "Add details with: bd comment $task_id 'implementation steps...'"

# Add research document to spec folder
new-research spec title:
    #!/usr/bin/env bash
    set -euo pipefail
    spec_dir=".claude/specs/{{spec}}"
    if [ ! -d "$spec_dir" ]; then
        echo "Spec folder not found: $spec_dir"
        exit 1
    fi
    mkdir -p "$spec_dir/research"
    filename=$(echo "{{title}}" | tr '[:upper:] ' '[:lower:]_' | tr -cd '[:alnum:]_').md
    filepath="$spec_dir/research/$filename"
    today=$(date +%Y-%m-%d)
    printf '%s\n' "# {{title}}" "" "**Date:** $today" "**Status:** In Progress" "" "## Question" "[What are we trying to find out?]" "" "## Findings" "[What did we discover?]" "" "## Recommendation" "[What do we suggest based on findings?]" "" "## Sources" "- [Links to references]" > "$filepath"
    echo "Created: $filepath"

# View spec with related tasks
view-spec name:
    #!/usr/bin/env bash
    set -euo pipefail
    spec_dir=".claude/specs/{{name}}"
    echo "# Spec: {{name}}"
    echo ""
    if [ -d "$spec_dir" ]; then
        echo "## Location: $spec_dir"
        echo ""
        if [ -f "$spec_dir/README.md" ]; then
            head -20 "$spec_dir/README.md"
            echo "..."
        fi
        echo ""
        echo "## Requirements"
        if [ -f "$spec_dir/requirements.md" ]; then
            grep -E "^## REQ-" "$spec_dir/requirements.md" 2>/dev/null || echo "(none defined)"
        fi
    else
        echo "Spec folder not found: $spec_dir"
    fi
    echo ""
    echo "## Epic & Tasks"
    # Find epic with spec:<name> label
    epic_id=$(bd list --json 2>/dev/null | jq -r --arg name "spec:{{name}}" '.[] | select(.labels[]? == $name) | .id' | head -1)
    if [ -n "$epic_id" ]; then
        echo "Epic: $epic_id"
        bd list --parent "$epic_id" 2>/dev/null || echo "(no tasks)"
    else
        echo "(no epic linked - run: just new-epic {{name}})"
    fi

# Find specs mentioning a topic
find-specs topic:
    @echo "Searching .claude/specs/ for: {{topic}}"
    @grep -r "{{topic}}" .claude/specs/ --include="*.md" -l 2>/dev/null || echo "No matches found"

# List all epics with their spec locations
list-epics:
    @bd list --json | jq -r '.[] | select(.labels[]? == "epic") | "\(.id)\t\(.labels | map(select(startswith("spec:"))) | first // "no spec")\t\(.title)"'

# === Orchestration ===

# Run combined spawner + merger loop
orchestrate *args:
    ./scripts/orchestrate.sh {{args}}

# Run orchestrator for a specific epic
orchestrate-epic epic max_agents="4":
    ./scripts/orchestrate.sh --epic {{epic}} --max-agents {{max_agents}}

# Run spawner only (launch workers for open tasks)
orchestrate-spawner *args:
    ./scripts/orchestrate.sh spawner {{args}}

# Run merger only (merge PRs, cleanup)
orchestrate-merger *args:
    ./scripts/orchestrate.sh merger {{args}}

# Preview orchestration without executing
orchestrate-preview *args:
    ./scripts/orchestrate.sh --dry-run {{args}}

# Show task status table
orchestrate-status:
    ./scripts/orchestrate.sh status

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

# List all agent logs
orchestrate-logs:
    ./scripts/orchestrate.sh logs

# Show full log for a specific agent
orchestrate-log task_id:
    ./scripts/orchestrate.sh log {{task_id}}

# Follow agent log output in real-time
orchestrate-tail task_id lines="50":
    ./scripts/orchestrate.sh tail {{task_id}} {{lines}}

# Show orchestration help
orchestrate-help:
    @echo "Orchestration Commands:"
    @echo ""
    @echo "  just orchestrate              Run combined spawner + merger loop"
    @echo "  just orchestrate --epic X     Run for specific epic"
    @echo "  just orchestrate-epic X       Shorthand for --epic"
    @echo ""
    @echo "  just orchestrate-spawner      Run spawner only (launch workers)"
    @echo "  just orchestrate-merger       Run merger only (merge PRs)"
    @echo "  just orchestrate-preview      Preview what would run (dry-run)"
    @echo ""
    @echo "  just orchestrate-status       Show task status table"
    @echo "  just orchestrate-logs         List all agent logs"
    @echo "  just orchestrate-log <id>     Show full log for an agent"
    @echo "  just orchestrate-tail <id>    Follow agent log in real-time"
    @echo ""
    @echo "  just worktree-clean           Remove all worktrees"
    @echo "  just worktree-remove <id>     Remove specific worktree"

# Run crash recovery tests
test-crash-recovery:
    ./scripts/test-crash-recovery.sh

# Migrate .claude/plan/ epics to beads
migrate-to-beads *args:
    ./scripts/migrate-plan-to-beads.sh {{args}}

# Preview migration without making changes
migrate-to-beads-preview:
    ./scripts/migrate-plan-to-beads.sh --dry-run

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

    # Copy to e2e/lustre/generated with appropriate names
    mkdir -p test/e2e/lustre/generated
    cp test/fixtures/simple/basic.gleam test/e2e/lustre/generated/basic.gleam 2>/dev/null || true
    cp test/fixtures/attributes/all_attrs.gleam test/e2e/lustre/generated/attributes.gleam 2>/dev/null || true
    cp test/fixtures/control_flow/full.gleam test/e2e/lustre/generated/control_flow.gleam 2>/dev/null || true
    cp test/fixtures/fragments/multiple_roots.gleam test/e2e/lustre/generated/fragments.gleam 2>/dev/null || true
    cp test/fixtures/custom_elements/web_components.gleam test/e2e/lustre/generated/custom_elements.gleam 2>/dev/null || true
    cp test/fixtures/edge_cases/special.gleam test/e2e/lustre/generated/edge_cases.gleam 2>/dev/null || true

    # Clean up generated files from fixtures directory
    rm -f test/fixtures/simple/basic.gleam
    rm -f test/fixtures/attributes/all_attrs.gleam
    rm -f test/fixtures/control_flow/full.gleam
    rm -f test/fixtures/fragments/multiple_roots.gleam
    rm -f test/fixtures/custom_elements/web_components.gleam
    rm -f test/fixtures/edge_cases/special.gleam

    # Fix import paths for generated modules (types -> e2e/lustre/generated/types)
    # Use platform-specific sed syntax (macOS vs Linux)
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' 's/^import types\./import e2e\/lustre\/generated\/types./' test/e2e/lustre/generated/control_flow.gleam
    else
        sed -i 's/^import types\./import e2e\/lustre\/generated\/types./' test/e2e/lustre/generated/control_flow.gleam
    fi

    # Format the generated files
    gleam format test/e2e/lustre/generated/

    echo "Generated SSR test modules:"
    ls -la test/e2e/lustre/generated/*.gleam
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

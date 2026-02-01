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

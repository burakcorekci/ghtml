# Lustre Template Generator - Development Commands
# Run `just` to see available commands
# Any unknown command falls through to gleam: `just add package` → `gleam add package`

# Default: show help
default:
    @just --list

# === Workflows ===

# Run all quality checks (build → test → integration → format → docs)
check:
    gleam build
    gleam test
    just integration
    gleam format
    gleam docs build
    @echo "✓ All checks passed"

# Simulate CI pipeline (matches .github/workflows/test.yml)
ci:
    gleam build
    gleam test
    just integration
    gleam format --check src test
    gleam docs build
    @echo "✓ CI simulation passed"

# === CLI Execution ===

# Run the CLI (default mode)
run:
    gleam run -m lustre_template_gen

# Run with force regeneration
run-force:
    gleam run -m lustre_template_gen -- force

# Run in watch mode
run-watch:
    gleam run -m lustre_template_gen -- watch

# Run orphan cleanup only
run-clean:
    gleam run -m lustre_template_gen -- clean

# === Examples ===

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
    if [ -d ".plan/{{name}}" ]; then
        echo "Error: Epic '.plan/{{name}}' already exists"
        exit 1
    fi
    cp -r .plan/_template ".plan/{{name}}"
    echo "✓ Created epic: .plan/{{name}}/"
    echo "  - Edit .plan/{{name}}/PLAN.md with your epic details"
    echo "  - Create tasks from .plan/{{name}}/tasks/000_template_task.md"

# === Utilities ===

# Clean build artifacts
clean:
    rm -rf build

# Run a specific test file (e.g., just test-file parser_tokenizer)
test-file name:
    gleam test -- --only {{name}}

# Run integration tests
# Creates test project, runs generator, verifies output compiles
integration:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Running integration tests..."

    # Create temporary test project
    TEST_DIR=$(mktemp -d)
    trap "rm -rf $TEST_DIR" EXIT

    mkdir -p "$TEST_DIR/src"

    # Create gleam.toml (not actually used by the generator, just for reference)
    cat > "$TEST_DIR/gleam.toml" << 'EOF'
    name = "test_project"
    version = "0.1.0"
    target = "erlang"
    [dependencies]
    gleam_stdlib = ">= 0.34.0"
    EOF

    # Create test template
    cat > "$TEST_DIR/src/test.lustre" << 'EOF'
    @params(name: String)
    <div class="greeting">{name}</div>
    EOF

    # Run generator with root directory argument
    echo "  Generating from template..."
    gleam run -m lustre_template_gen -- "$TEST_DIR"

    # Verify output exists
    if [ ! -f "$TEST_DIR/src/test.gleam" ]; then
        echo "ERROR: test.gleam was not generated"
        exit 1
    fi

    # Verify output contains expected content
    echo "  Verifying generated content..."
    grep -q "@generated" "$TEST_DIR/src/test.gleam" || { echo "ERROR: Missing @generated header"; exit 1; }
    grep -q "pub fn render" "$TEST_DIR/src/test.gleam" || { echo "ERROR: Missing render function"; exit 1; }
    grep -q "name: String" "$TEST_DIR/src/test.gleam" || { echo "ERROR: Missing parameter"; exit 1; }

    echo "  Integration tests passed!"

# === Gleam Passthrough ===

# Pass any other command to gleam (e.g., just add package → gleam add package)
[positional-arguments]
@g *args:
    gleam {{args}}

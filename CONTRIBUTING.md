# Contributing to lustre_template_gen

Thanks for your interest in contributing! Here's everything you need to get started.

## Development Setup

```bash
# Clone and enter the repo
git clone https://github.com/burakcorekci/lustre_template_gen
cd lustre_template_gen

# Install dependencies
gleam deps download

# Run the checks to make sure everything works
just check
```

## Commands

We use [just](https://github.com/casey/just) as our command runner. Run `just` to see all available commands.

### Everyday Commands

| Command | What it does |
|---------|--------------|
| `just check` | Run all quality checks (build, test, format, docs) |
| `just test` | Run all tests |
| `just unit` | Run unit tests only (fast!) |
| `just integration` | Run integration tests |

### Running the CLI

| Command | What it does |
|---------|--------------|
| `just run` | Generate templates (skips unchanged) |
| `just run-force` | Force regenerate everything |
| `just run-watch` | Watch mode - auto-regenerates on changes |
| `just run-clean` | Remove orphaned generated files |

### Other Useful Commands

| Command | What it does |
|---------|--------------|
| `just ci` | Simulate the CI pipeline locally |
| `just clean` | Remove build artifacts |
| `just examples` | Build all example projects |
| `just g <cmd>` | Passthrough to gleam (e.g., `just g add package`) |

## Project Structure

```
src/
├── lustre_template_gen.gleam     # CLI entry point
└── lustre_template_gen/
    ├── types.gleam               # All shared types (Token, Node, Template, etc.)
    ├── parser.gleam              # Tokenizer + AST builder
    ├── codegen.gleam             # AST → Gleam code generation
    ├── scanner.gleam             # File discovery (.lustre files, orphans)
    ├── cache.gleam               # Hash-based caching logic
    └── watcher.gleam             # Watch mode (OTP actor)

test/
├── unit/                         # Fast, isolated tests
│   ├── parser/                   # Tokenizer and AST tests
│   └── codegen/                  # Code generation tests
├── integration/                  # Pipeline tests
└── fixtures/                     # Shared test fixtures
```

## Architecture

```
.lustre file → Scanner → Parser → Codegen → .gleam file
                           │
                    ┌──────┴──────┐
                    │             │
               tokenize()    build_ast()
                    │             │
                    └──────┬──────┘
                           │
                      Template {
                        imports,
                        params,
                        body: List(Node)
                      }
```

### Key Modules

- **parser.gleam**: Two-phase parsing - `tokenize()` produces tokens, `build_ast()` produces the AST
- **codegen.gleam**: Transforms the AST into valid Gleam source code with smart imports
- **cache.gleam**: SHA-256 content hashing to skip unchanged templates
- **watcher.gleam**: OTP actor that polls for changes every second

## Test-Driven Development

We follow TDD. When adding features:

1. **Write failing tests first** in the appropriate `test/unit/` or `test/integration/` directory
2. **Implement the simplest thing** that makes tests pass
3. **Refactor** to the cleanest solution

## Adding Features

### New Attribute

1. Add to `known_attributes` list in `codegen.gleam`
2. If boolean, add to `boolean_attributes` list
3. Add tests in `test/unit/codegen/attributes_test.gleam`

### New Control Flow Construct

1. Add token type in `types.gleam`
2. Add tokenization in `parser.gleam` (`tokenize_loop`)
3. Add stack frame type for nesting
4. Add AST node handling in `build_ast`
5. Add codegen in `codegen.gleam`
6. Add tests in `test/unit/codegen/control_flow_test.gleam`

## Code Style

- Run `gleam format` before committing
- Keep functions small and focused
- Use descriptive names over comments
- Error types should include position information for good error messages

## Questions?

Open an issue! We're happy to help.

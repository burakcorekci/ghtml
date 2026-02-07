# Codebase Overview

This document provides context for agents working on this project. Read this first before implementing any task.

## What This Project Does

**ghtml** (Gleam HTML Template Generator) is a Gleam preprocessor that converts `.ghtml` template files into Gleam modules with Lustre `Element(msg)` render functions.

**Flow:** `.ghtml` file → Lexer (tokenize) → Parser (AST) → Codegen → `.gleam` file

**Example:**
```
src/components/user_card.ghtml  →  src/components/user_card.gleam
```

## Quick Reference

| Task | Command |
|------|---------|
| Run all checks | `just check` |
| Simulate CI | `just ci` |
| Run unit+integration tests | `just test` |
| Run unit tests | `just unit` |
| Run integration tests | `just integration` |
| Run E2E tests | `just e2e` |
| Regenerate E2E modules | `just e2e-regen` |
| Build | `just g build` |
| Run CLI | `just run` |
| Force regenerate | `just run-force` |
| Watch mode | `just run-watch` |
| Clean orphans | `just run-clean` |
| Validate examples | `just check-examples` |
| Regenerate GIFs | `just gifs` |

## Architecture

```
                    ┌──────────────────────────────────────────────────────────┐
                    │                    CLI Entry Point                        │
                    │              ghtml.gleam                    │
                    │  - Parses CLI args (force, clean, watch, --target)        │
                    │  - Orchestrates scanning → generation → cleanup           │
                    └───────────────────────┬──────────────────────────────────┘
                                            │
        ┌───────────────────────────────────┼───────────────────────────────────┐
        │                                   │                                   │
        ▼                                   ▼                                   ▼
┌───────────────────┐            ┌──────────────────────┐            ┌───────────────────┐
│     scanner       │            │       parser         │            │      watcher      │
│  - Find .ghtml   │            │  - parse() = lex+ast │            │  - OTP actor      │
│  - Find .gleam    │            │  - build_ast()       │            │  - Poll every 1s  │
│  - Find orphans   │            │  - format_error()    │            │  - Track mtimes   │
└───────────────────┘            └──────────┬───────────┘            └───────────────────┘
                                            │
                                            ▼
                               ┌──────────────────────┐
                               │        lexer         │
                               │  - tokenize()        │
                               │  - HTML/attr parsing │
                               │  - Brace balancing   │
                               └──────────────────────┘
                                            │
                                            ▼
                    ┌──────────────────────────────────────────────────────────┐
                    │                 codegen (dispatcher)                       │
                    │  - generate(template, path, hash, target) → String        │
                    │  - Routes to target-specific backend by Target type       │
                    └───────────────────────┬──────────────────────────────────┘
                                            │
                                            ▼
                    ┌──────────────────────────────────────────────────────────┐
                    │              target/lustre.gleam                          │
                    │  - Lustre-specific code generation                        │
                    │  - Smart imports, attrs, events, control flow             │
                    │  - Uses codegen_utils for shared helpers                  │
                    └──────────────────────────────────────────────────────────┘
                                            │
                                            ▼
                    ┌──────────────────────────────────────────────────────────┐
                    │                        cache                              │
                    │  - SHA-256 hashing of source content                      │
                    │  - Hash stored in generated file header                   │
                    │  - Skip regeneration if hash unchanged                    │
                    └──────────────────────────────────────────────────────────┘
```

## Module Guide

### `src/ghtml.gleam` - CLI Entry Point
- Parses command-line arguments (force, clean, watch, --target, root directory)
- Coordinates the generation pipeline, threading Target through all stages
- Public: `main()`, `generate_all(root, force, target)`, `parse_options(args) -> Result(CliOptions, String)`
- Supports specifying a root directory: `gleam run -m ghtml -- ./my-project`
- Supports specifying a target: `gleam run -m ghtml -- --target=lustre`

### `src/ghtml/types.gleam` - Core Types
All shared types are defined here:
- **Position/Span** - Source locations for error reporting
- **Token** - Lexer output (Import, Params, HtmlOpen, IfStart, etc.)
- **Attribute** - Attribute variants (StaticAttribute, DynamicAttribute, EventAttribute with modifiers: List(String), BooleanAttribute)
- **Node** - AST nodes (Element, TextNode, ExprNode, IfNode, EachNode, CaseNode, Fragment)
- **Template** - Final parsed result with imports, params, and body nodes
- **Target** - Code generation target backend (currently: Lustre). Includes `target_from_string()` and `valid_target_names()`.

### `src/ghtml/lexer.gleam` - Lexer
Tokenizes template source text into a flat list of tokens:
- `tokenize(input) -> Result(List(Token), List(ParseError))` - Lexical analysis

Handles all tokenization concerns:
- Position tracking (line/column)
- Import/params directive parsing
- HTML tag parsing (open, close, self-closing, attributes)
- Brace content parsing (expressions, control flow: if/each/case)
- Text parsing with `{{`/`}}` escape sequences
- HTML comment stripping
- Brace balancing for nested expressions like `{fn({a: 1})}`

### `src/ghtml/parser.gleam` - Parser
Builds AST from tokens produced by the lexer:
1. `parse(input) -> Result(Template, List(ParseError))` - Combined tokenize + AST
2. `build_ast(tokens) -> Result(List(Node), List(ParseError))` - Tree construction from tokens

Key concepts:
- Delegates tokenization to `ghtml/lexer`
- Uses a stack-based approach for nesting (elements, if/each/case blocks)
- Extracts metadata (imports, params) from token stream

### `src/ghtml/codegen.gleam` - Code Generation Dispatcher
Thin dispatcher that routes code generation to the appropriate target:
- `generate(template, source_path, hash, target) -> String`
- Dispatches by `Target` type (currently only `Lustre`)
- Adding a new target: new `Target` variant, new file in `target/`, new case branch

### `src/ghtml/codegen_utils.gleam` - Shared Codegen Utilities
Target-agnostic helpers used by all code generation backends:
- Template analysis: `template_has_each()`, `template_needs_none()`, etc.
- String utilities: `escape_string()`, `normalize_whitespace()`, `is_blank()`
- HTML helpers: `is_custom_element()`, `is_void_element()`
- Import detection: `has_user_import()`, `extract_filename()`

### `src/ghtml/target/lustre.gleam` - Lustre Target Backend
Lustre-specific code generation:
- `generate(template, source_path, hash) -> String`
- Smart imports: only includes `gleam/list` if `{#each}` is used, etc.
- Handles attribute mapping (class→attribute.class, @click→event.on_click)
- Custom elements (tags with `-`) use `element("tag-name", ...)` instead of `html.tag()`

### `src/ghtml/scanner.gleam` - File Discovery
- `find_lustre_files(root)` - Recursively find `.ghtml` files
- `find_orphans(root)` - Find generated files with no source
- `cleanup_orphans(root)` - Delete orphaned generated files
- Ignores: `build`, `.git`, `node_modules`, `_build`, `.claude`, `fixtures`

### `src/ghtml/cache.gleam` - Caching Logic
- `hash_content(content) -> String` - SHA-256 hex digest
- `needs_regeneration(source, output) -> Bool` - Compare hashes
- `is_generated(content) -> Bool` - Check for `// @generated` header

### `src/ghtml/watcher.gleam` - Watch Mode
- OTP actor that polls for file changes every 500ms
- Accepts Target parameter and threads it through code generation
- Tracks file modification times
- Auto-regenerates on change, cleans up on delete

### `test/e2e_helpers.gleam` - E2E Test Helpers
Utilities for E2E testing:
- `create_temp_dir(prefix)` - Create unique temp directory in `.test/`
- `cleanup_temp_dir(path)` - Remove temp directory and contents
- `copy_directory(src, dest)` - Recursive directory copy
- `run_command(cmd, args, cwd)` - Execute shell commands
- `gleam_build(project_dir)` - Run `gleam build` in a directory
- Path helpers: `fixtures_dir()`, `e2e_dir()`, `project_template_dir()`, `generated_dir()`

## Template Syntax Quick Reference

```html
@import(gleam/int)
@import(app/types.{type User, Admin, Member})

@params(
  user: User,
  items: List(String),
  on_click: fn() -> msg,
)

<div class="container" id={dynamic_id}>
  <p>{user.name}</p>

  {#if user.is_admin}
    <span>Admin</span>
  {:else}
    <span>User</span>
  {/if}

  {#each items as item, index}
    <li>{int.to_string(index)}: {item}</li>
  {/each}

  {#case user.role}
    {:Admin}
      <span>Admin</span>
    {:Member(since)}
      <span>Member since {int.to_string(since)}</span>
  {/case}

  <button @click={on_click()}>Click me</button>
  <div @on:dragover.prevent={on_dragover()}>Drop here</div>
  <div @click.stop.prevent={handle()}>No bubbling</div>
</div>
```

Event modifiers:
- `.prevent` → wraps with `event.prevent_default()`
- `.stop` → wraps with `event.stop_propagation()`
- Can be combined: `@click.prevent.stop={handler}`

## Test Structure

Tests are organized by type (unit/integration/e2e) with target-specific tests under `target/<name>` or `<name>/` subdirectories:
```
test/
  ghtml_test.gleam                    # Test entry point (gleeunit)
  e2e_helpers.gleam                   # E2E test helper utilities
  unit/                               # Fast, isolated module tests
    scanner_test.gleam                # Scanner tests
    cli_test.gleam                    # CLI tests
    cache_test.gleam                  # Cache tests
    watcher_test.gleam                # Watcher tests
    types_test.gleam                  # Type tests
    lexer_test.gleam                  # Tokenizer tests
    parser_test.gleam                 # AST builder tests
    codegen/
      dispatcher_test.gleam           # Shared dispatcher tests
    target/
      lustre/
        basic_test.gleam              # Basic element codegen (Lustre)
        attributes_test.gleam         # Attribute handling (Lustre)
        control_flow_test.gleam       # if/each/case codegen (Lustre)
        imports_test.gleam            # Smart import tests (Lustre)
  integration/                        # Pipeline tests
    lustre/
      pipeline_test.gleam             # Lustre pipeline tests
  e2e/                                # E2E tests (slow, require build)
    helpers_test.gleam                # Tests for e2e_helpers module (target-agnostic)
    lustre/
      build_test.gleam                # Build verification tests
      generated_modules_test.gleam    # Generated module validation
      lustre_dep_test.gleam           # Lustre dependency tests
      project_template_test.gleam     # Project template tests
      ssr_test.gleam                  # Server-side rendering tests
      generated/                      # Pre-generated modules for SSR tests
        basic.gleam, attributes.gleam, control_flow.gleam, etc.
      project_template/               # Minimal Gleam project for E2E tests
  fixtures/                           # Shared test fixtures (ignored by scanner)
    simple/basic.ghtml                # Simple template fixture
    attributes/all_attrs.ghtml        # Attributes fixture
    control_flow/full.ghtml           # Control flow fixture
    fragments/multiple_roots.ghtml    # Fragment/multi-root fixture
    custom_elements/web_components.ghtml  # Custom element fixture
    edge_cases/special.ghtml          # Edge case fixture
```

Run tests with:
- `just unit` - Run unit tests only (fast)
- `just integration` - Run integration tests
- `just test` - Run unit + integration tests
- `just e2e` - Run E2E tests (slower, requires build)

## Examples

The `examples/` directory contains complete, buildable examples demonstrating ghtml features:

```
examples/
  01_simple/         # Basic template with text interpolation
  02_attributes/     # Static, dynamic, and boolean attributes
  03_events/         # Event handlers (@click, @input, etc.)
  04_control_flow/   # {#if}, {#each}, {#case} blocks
  05_shoelace/       # Shoelace web components integration
  06_material_web/   # Material Web components integration
  07_tailwind/       # Tailwind CSS styling
  08_complete/       # Full application with all features
  09_drag_drop/      # HTML5 drag & drop with event modifiers (.prevent, .stop)
```

Each example is a standalone Gleam project with its own `gleam.toml` and `justfile`.
- Build all examples: `just examples`
- Validate examples: `just check-examples` (runs during CI)
- Clean examples: `just examples-clean`

## Key Design Decisions

1. **All interpolated values must be `String`** - No automatic type conversion
2. **Expressions are passed verbatim** - The generator doesn't validate Gleam syntax
3. **Whitespace is collapsed** - Multiple spaces/newlines become single space
4. **`{#each}` uses `keyed()`** - For Lustre performance optimization
5. **Boolean attrs differ by element type** - Standard HTML vs custom elements
6. **Imports are conditional** - Only include what's actually used

## Dependencies

| Package | Purpose |
|---------|---------|
| `gleam_stdlib` | Standard library |
| `simplifile` | File system operations |
| `argv` | CLI argument parsing |
| `gleam_crypto` | SHA-256 hashing |
| `gleam_erlang` | Process/timer for watch mode |
| `gleam_otp` | Actor for watch mode |
| `shellout` | Shell command execution |
| `gleeunit` | Testing (dev) |
| `lustre` | For SSR testing (dev) |

## Beads Workflow

Beads is a git-backed issue tracker used for orchestration and multi-session task management.

### Task Lifecycle
1. Create: `bd create "Task subject" -p 1`
2. Start: `bd update <id> --status in_progress`
3. Complete: `bd close <id>`

### Phase Tracking (Labels)
Orchestrator tracks phases via labels:
- `phase:spawned` - Worktree created, agent starting
- `phase:working` - Agent actively implementing
- `phase:committed` - Changes committed, ready for PR
- `phase:pr_created` - PR created, awaiting merge
- `phase:merged` - PR merged, task complete

### Runtime State (Local)
Runtime data stored in `.beads/orchestrator/state.json` (git-ignored):
- `pid` - Agent process ID
- `worktree` - Git worktree path
- `pr_number` - GitHub PR number

### Querying
- Ready tasks: `bd ready`
- Active tasks: `bd list --status in_progress`
- By phase: `bd list --json | jq '.[] | select(.labels[]? | contains("phase:working"))'`
- Full state: `bd list --json`

### Orchestration Commands
See `.claude/docs/orchestration.md` for full guide. Quick reference:
- `just orchestrate` - Run for all ready tasks
- `just orchestrate-status` - Show current state
- `just worker <id>` - Spawn single worker
- `just merger` - Process PRs

## Common Patterns

### Error Handling
Parser errors include source positions:
```gleam
ParseError(span: Span, message: String)
```

### Adding a New Attribute
1. Add to `known_attributes` list in `codegen.gleam`
2. If boolean, add to `boolean_attributes` list
3. Add tests in `test/unit/target/lustre/attributes_test.gleam`

### Adding a New Control Flow Construct
1. Add token type in `types.gleam`
2. Add tokenization in `lexer.gleam` (`tokenize_loop`)
3. Add stack frame type for nesting in `parser.gleam`
4. Add AST node handling in `build_ast` in `parser.gleam`
5. Add codegen in `codegen.gleam`
6. Add tests in `test/unit/target/lustre/control_flow_test.gleam`

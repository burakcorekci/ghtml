# Codebase Overview

This document provides context for agents working on this project. Read this first before implementing any task.

## What This Project Does

**Lustre Template Generator** is a Gleam preprocessor that converts `.lustre` template files into Gleam modules with Lustre `Element(msg)` render functions.

**Flow:** `.lustre` file → Parser (tokenize + AST) → Codegen → `.gleam` file

**Example:**
```
src/components/user_card.lustre  →  src/components/user_card.gleam
```

## Quick Reference

| Task | Command |
|------|---------|
| Run all checks | `just check` |
| Run tests only | `just g test` |
| Build | `just g build` |
| Run CLI | `just run` |
| Force regenerate | `just run-force` |
| Watch mode | `just run-watch` |

## Architecture

```
                    ┌──────────────────────────────────────────────────────────┐
                    │                    CLI Entry Point                        │
                    │              lustre_template_gen.gleam                    │
                    │  - Parses CLI args (force, clean, watch)                  │
                    │  - Orchestrates scanning → generation → cleanup           │
                    └───────────────────────┬──────────────────────────────────┘
                                            │
        ┌───────────────────────────────────┼───────────────────────────────────┐
        │                                   │                                   │
        ▼                                   ▼                                   ▼
┌───────────────────┐            ┌──────────────────────┐            ┌───────────────────┐
│     scanner       │            │       parser         │            │      watcher      │
│  - Find .lustre   │            │  - tokenize()        │            │  - OTP actor      │
│  - Find .gleam    │            │  - build_ast()       │            │  - Poll every 1s  │
│  - Find orphans   │            │  - parse() = both    │            │  - Track mtimes   │
└───────────────────┘            └──────────┬───────────┘            └───────────────────┘
                                            │
                                            ▼
                    ┌──────────────────────────────────────────────────────────┐
                    │                       codegen                             │
                    │  - generate() → String (Gleam source code)                │
                    │  - Smart imports based on feature usage                   │
                    │  - Handles: elements, attrs, events, control flow         │
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

### `src/lustre_template_gen.gleam` - CLI Entry Point
- Parses command-line arguments (force, clean, watch, root directory)
- Coordinates the generation pipeline
- Public: `main()`, `generate_all()`, `parse_options()`
- Supports specifying a root directory: `gleam run -m lustre_template_gen -- ./my-project`

### `src/lustre_template_gen/types.gleam` - Core Types
All shared types are defined here:
- **Position/Span** - Source locations for error reporting
- **Token** - Lexer output (Import, Params, HtmlOpen, IfStart, etc.)
- **Attr** - Attribute variants (StaticAttr, DynamicAttr, EventAttr, BooleanAttr)
- **Node** - AST nodes (Element, TextNode, ExprNode, IfNode, EachNode, CaseNode, Fragment)
- **Template** - Final parsed result with imports, params, and body nodes

### `src/lustre_template_gen/parser.gleam` - Parser
Two-phase parsing:
1. `tokenize(input) -> Result(List(Token), List(ParseError))` - Lexical analysis
2. `build_ast(tokens) -> Result(List(Node), List(ParseError))` - Tree construction
3. `parse(input) -> Result(Template, List(ParseError))` - Combined convenience function

Key concepts:
- Uses a stack-based approach for nesting (elements, if/each/case blocks)
- Handles brace balancing for expressions like `{fn({a: 1})}`
- Supports `{{` and `}}` escape sequences for literal braces

### `src/lustre_template_gen/codegen.gleam` - Code Generator
Transforms AST → Gleam source:
- `generate(template, source_path, hash) -> String`
- Smart imports: only includes `gleam/list` if `{#each}` is used, etc.
- Handles attribute mapping (class→attribute.class, @click→event.on_click)
- Custom elements (tags with `-`) use `element("tag-name", ...)` instead of `html.tag()`

### `src/lustre_template_gen/scanner.gleam` - File Discovery
- `find_lustre_files(root)` - Recursively find `.lustre` files
- `find_orphans(root)` - Find generated files with no source
- `cleanup_orphans(root)` - Delete orphaned generated files
- Ignores: `build`, `.git`, `node_modules`, `_build`, `.plan`, `fixtures`

### `src/lustre_template_gen/cache.gleam` - Caching Logic
- `hash_content(content) -> String` - SHA-256 hex digest
- `needs_regeneration(source, output) -> Bool` - Compare hashes
- `is_generated(content) -> Bool` - Check for `// @generated` header

### `src/lustre_template_gen/watcher.gleam` - Watch Mode
- OTP actor that polls for file changes every second
- Tracks file modification times
- Auto-regenerates on change, cleans up on delete

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
</div>
```

## Test Structure

Tests mirror the source structure:
```
test/
  lustre_template_gen_test.gleam      # Main test entry
  integration_test.gleam              # End-to-end integration tests
  fixtures/                           # Test fixtures (ignored by scanner)
    simple/basic.lustre               # Simple template fixture
    attributes/all_attrs.lustre       # Attributes fixture
    control_flow/full.lustre          # Control flow fixture
  lustre_template_gen/
    types_test.gleam                  # Type tests
    cache_test.gleam                  # Cache tests
    scanner_test.gleam                # Scanner tests
    cli_test.gleam                    # CLI tests
    watcher_test.gleam                # Watcher tests
    parser/
      tokenizer_test.gleam            # Tokenizer tests
      ast_test.gleam                  # AST builder tests
    codegen/
      basic_test.gleam                # Basic element codegen
      attributes_test.gleam           # Attribute handling
      control_flow_test.gleam         # if/each/case codegen
      imports_test.gleam              # Smart import tests
```

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
| `gleeunit` | Testing (dev) |

## Common Patterns

### Error Handling
Parser errors include source positions:
```gleam
ParseError(span: Span, message: String)
```

### Adding a New Attribute
1. Add to `known_attributes` list in `codegen.gleam`
2. If boolean, add to `boolean_attributes` list
3. Add tests in `test/lustre_template_gen/codegen/attributes_test.gleam`

### Adding a New Control Flow Construct
1. Add token type in `types.gleam`
2. Add tokenization in `parser.gleam` (`tokenize_loop`)
3. Add stack frame type for nesting
4. Add AST node handling in `build_ast`
5. Add codegen in `codegen.gleam`
6. Add tests in `test/lustre_template_gen/codegen/control_flow_test.gleam`

## Planning Structure

The `.plan/` directory is the main planning folder for multi-session work. It organizes work into epics with tasks.

### Directory Structure

```
.plan/
├── _template/                    # Templates for creating new epics
│   ├── PLAN.md                   # Epic plan template
│   └── tasks/
│       ├── README.md             # Tasks overview template
│       └── 000_template_task.md  # Individual task template
├── initial_implementation/       # Example completed epic
│   ├── PLAN.md                   # High-level epic plan
│   └── tasks/
│       ├── README.md             # Task overview and status
│       ├── 001_project_setup.md  # Individual task specs
│       ├── 002_types_module.md
│       └── ...
└── [next_epic]/                  # Future epics follow same structure
```

### Epic Structure

Each epic directory contains:

1. **`PLAN.md`** - High-level plan with:
   - Goal and background
   - Scope (in/out)
   - Design overview
   - Task breakdown table
   - Dependency graph
   - Success criteria

2. **`tasks/`** - Individual task specifications:
   - Named with numeric prefix: `001_task_name.md`
   - Each task is independently executable when dependencies are met
   - Contains implementation steps, test cases, and verification checklist

### Creating a New Epic

1. Copy the template: `cp -r .plan/_template .plan/your_epic_name`
2. Edit `PLAN.md` with your epic's details
3. Create task files from `tasks/000_template_task.md`
4. Update `tasks/README.md` with task status tracking

### Task Execution Guidelines

- Tasks are designed to leave the codebase in a working state
- Each task should result in a single atomic commit
- Follow TDD: write tests first, then implement
- Run `just check` before marking a task complete
- Commit message format: `epic_name: task description`

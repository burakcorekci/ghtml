# Design

## Overview

Restructure ghtml from a single-backend template compiler into a multi-target architecture. The parser and AST remain backend-agnostic while each target module handles framework-specific code generation. This is an internal refactoring — no package boundaries change.

## Current State

```
src/
  ghtml.gleam              CLI entry point (157 lines)
  ghtml/
    types.gleam            All types: Position, Span, Token, Attr, Node, Template (103 lines)
    parser.gleam           Tokenizer + AST builder combined (1713 lines)
    codegen.gleam          Lustre codegen, mixed with shared utils (783 lines)
    scanner.gleam          File discovery (110 lines)
    cache.gleam            Hash-based caching (67 lines)
    watcher.gleam          OTP file watcher (209 lines)
```

**Key coupling insight:** Parser and codegen are already cleanly separated — they communicate only through types.gleam. Codegen has zero Lustre imports; all Lustre knowledge is embedded as string constants. Extraction difficulty is low.

## Target State

```
src/
  ghtml.gleam              CLI entry point (updated: --target flag, passes Target)
  ghtml/
    types.gleam            Core types + Target type (updated: generic modifiers, renames)
    lexer.gleam            NEW: tokenize() extracted from parser
    parser.gleam           MODIFIED: build_ast() only, calls lexer
    codegen.gleam          MODIFIED: thin dispatcher + shared utils
    scanner.gleam          unchanged
    cache.gleam            unchanged
    watcher.gleam          MODIFIED: accepts Target parameter
    target/
      lustre.gleam         NEW: all current Lustre codegen logic moved here
```

## Components

### 1. AST Types (`types.gleam`)

**Changes:**

```gleam
// BEFORE
pub type Attr {
  StaticAttr(name: String, value: String)
  DynamicAttr(name: String, expr: String)
  EventAttr(event: String, handler: String, prevent_default: Bool, stop_propagation: Bool)
  BooleanAttr(name: String)
}

// AFTER
pub type Attribute {
  StaticAttribute(name: String, value: String)
  DynamicAttribute(name: String, expr: String)
  EventAttribute(event: String, handler: String, modifiers: List(String))
  BooleanAttribute(name: String)
}
```

**New type:**
```gleam
pub type Target {
  Lustre
  // Future: StringTree, String, Reactive
}
```

All other types (Position, Span, Token, Node, Template, etc.) remain unchanged. The Node type already uses Span for error reporting — this is framework-agnostic and stays.

### 2. Lexer (`lexer.gleam`) — New Module

Extracted from `parser.gleam`. Contains:
- `pub fn tokenize(input: String) -> Result(List(Token), List(ParseError))`
- All tokenization helper functions (currently private in parser.gleam):
  - Token recognition (HTML tags, expressions, control flow markers)
  - Brace balancing for expressions like `{fn({a: 1})}`
  - `{{` / `}}` escape sequences
  - Position/span tracking during tokenization
  - Attribute parsing (static, dynamic, event with modifiers, boolean)

### 3. Parser (`parser.gleam`) — Slimmed Down

After extraction, contains only:
- `pub fn parse(input: String) -> Result(Template, List(ParseError))` — convenience function
- `pub fn build_ast(tokens: List(Token)) -> Result(List(Node), List(ParseError))` — AST construction
- Stack-based nesting logic
- Import/params extraction

```gleam
// parse() becomes:
pub fn parse(input: String) -> Result(Template, List(ParseError)) {
  use tokens <- result.try(lexer.tokenize(input))
  // ... extract imports, params, build AST ...
}
```

### 4. Codegen Dispatcher (`codegen.gleam`) — Refactored

Becomes a thin dispatcher plus shared utilities:

```gleam
import ghtml/target/lustre
import ghtml/types.{type Target, type Template, Lustre}

/// Route to appropriate target backend
pub fn generate(template: Template, source_path: String, hash: String, target: Target) -> String {
  case target {
    Lustre -> lustre.generate(template, source_path, hash)
  }
}

// --- Shared utilities below (used by all targets) ---

pub fn escape_string(s: String) -> String { ... }
pub fn normalize_whitespace(text: String) -> String { ... }
pub fn is_blank(text: String) -> Bool { ... }
pub fn is_custom_element(tag: String) -> Bool { ... }
pub fn is_void_element(tag: String) -> Bool { ... }

// AST analysis helpers
pub fn template_has_events(nodes: List(Node)) -> Bool { ... }
pub fn template_has_attrs(nodes: List(Node)) -> Bool { ... }
pub fn template_has_each(nodes: List(Node)) -> Bool { ... }
// ... etc
```

### 5. Lustre Target (`target/lustre.gleam`) — New Module

All Lustre-specific code moves here:

```gleam
import ghtml/codegen  // shared utilities
import ghtml/cache
import ghtml/types.{type Attribute, type CaseBranch, type Node, type Template, ...}

/// Lustre-specific constants
const known_attributes = [
  #("class", "attribute.class"),
  #("id", "attribute.id"),
  // ... all 21 attribute mappings
]

const boolean_attributes = ["disabled", "readonly", "checked", ...]

/// Generate Lustre code from a parsed template
pub fn generate(template: Template, source_path: String, hash: String) -> String { ... }

// All Lustre-specific generation functions:
// - generate_imports() — lustre/element, lustre/event, etc.
// - generate_element_inline() — html.div(...), element("tag", ...)
// - generate_event_attr() — event.on_click(...), modifier wrapping
// - generate_each_node_inline() — keyed.fragment(list.map(...))
// etc.
```

**Event modifier interpretation (Lustre-specific):**
```gleam
fn apply_modifiers(base: String, modifiers: List(String)) -> String {
  list.fold(modifiers, base, fn(acc, modifier) {
    case modifier {
      "prevent" -> "event.prevent_default(" <> acc <> ")"
      "stop" -> "event.stop_propagation(" <> acc <> ")"
      _ -> acc  // Unknown modifiers ignored (or warn)
    }
  })
}
```

### 6. CLI (`ghtml.gleam`) — Updated

```gleam
// New argument parsing
pub fn parse_options(args: List(String)) -> Options {
  // Existing: --force, --clean, --watch, root dir
  // New: --target=lustre (default)
  ...
}

pub type Options {
  Options(
    force: Bool,
    clean: Bool,
    watch: Bool,
    root: String,
    target: Target,  // NEW
  )
}
```

### 7. Watcher (`watcher.gleam`) — Updated

Updated to accept and pass through `Target`:

```gleam
pub fn start_watching(root: String, target: Target) -> ...
// process_single_file passes target to codegen.generate()
```

## Data Flow

```
                                              ┌─────────────────────┐
                                              │  target/lustre.gleam│
                                              │  (Lustre codegen)   │
                                              └────────▲────────────┘
                                                       │
                                                  dispatched by
                                                       │
.ghtml ──► lexer.tokenize() ──► parser.build_ast() ──► codegen.generate(target)
                                       │                       │
                                       ▼                       │ uses
                                   Template                    ▼
                                                       ┌───────────────┐
                                                       │codegen (shared)│
                                                       │escape_string  │
                                                       │is_void_element│
                                                       │AST traversals │
                                                       └───────────────┘
```

**Future targets plug in here:**
```
codegen.generate(target) ──► case target {
                               Lustre     → target/lustre.generate(...)
                               StringTree → target/stringtree.generate(...)  // future
                               Reactive   → target/reactive.generate(...)   // future
                             }
```

## Interfaces

### codegen.generate (updated signature)

```gleam
// Before
pub fn generate(template: Template, source_path: String, hash: String) -> String

// After
pub fn generate(template: Template, source_path: String, hash: String, target: Target) -> String
```

### Target module contract

Every target module must implement:
```gleam
pub fn generate(template: Template, source_path: String, hash: String) -> String
```

This isn't enforced by a trait/interface (Gleam doesn't have them) but is a convention. Each target receives the parsed Template and produces a complete Gleam source file string.

### CLI flag

```bash
gleam run -m ghtml                       # Default: lustre
gleam run -m ghtml -- --target=lustre    # Explicit
gleam run -m ghtml -- --target=foo       # Error: "Unknown target 'foo'. Valid targets: lustre"
```

## Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Internal refactor, not package split | Gleam monorepo tooling is immature. Split later when APIs stabilize. | Immediate package extraction (deferred to future) |
| `modifiers: List(String)` for events | Generic, extensible, no framework coupling in AST | Keep booleans (Lustre-specific), `Dict(String, Bool)` (over-engineered) |
| Full type renames (Attr→Attribute) | Consistency, readability for multi-backend audience | Keep abbreviations (less churn), partial rename |
| Shared utils in `codegen.gleam` | Colocation with dispatcher, avoid proliferating small modules | Separate `codegen/utils.gleam` (unnecessary indirection for now) |
| AST analysis helpers stay shared | All targets need to know "does this template use events?" for import decisions | Per-target analysis (duplicated logic) |
| `target/` directory under `ghtml/` | Clear namespace, matches Target type variants | `backend/` (less standard), `gen/` (ambiguous) |
| Convention-based target interface | Gleam has no traits/interfaces. Convention + docs is sufficient. | Callback type (too heavy for 1:1 dispatch) |
| Default target is `lustre` | Backwards compatibility. Most users want Lustre. | Require explicit target (breaking change) |

## Error Handling

### Invalid target in CLI
```
Error: Unknown target 'foo'
Valid targets: lustre
```

### Future: Events in non-interactive target
When StringTree/String targets are added, templates with event handlers should produce a clear compile-time error:
```
Error: Template 'user_card.ghtml' uses event handlers (@click), which are not supported by the 'stringtree' target.
Hint: Use --target=lustre for interactive templates.
```
This is NOT part of the current implementation (only Lustre target exists).

## Migration Path

### Phase 1: AST Cleanup
1. Rename `Attr` → `Attribute` (and variants)
2. Change `EventAttr` to use `modifiers: List(String)`
3. Update parser to produce new modifier format
4. Update codegen to consume new modifier format
5. Update all tests
6. `just check` passes — no functional change

### Phase 2: Parser Split
1. Create `lexer.gleam` with `tokenize()` extracted from parser
2. Update `parser.gleam` to import and call `lexer.tokenize()`
3. Move tokenizer tests to point at `ghtml/lexer`
4. `just check` passes — no functional change

### Phase 3: Target Architecture
1. Add `Target` type to `types.gleam`
2. Create `target/lustre.gleam` — move all Lustre codegen from `codegen.gleam`
3. Refactor `codegen.gleam` to dispatcher + shared utils
4. Add `--target` CLI flag with `lustre` default
5. Update `ghtml.gleam` and `watcher.gleam` to pass target through pipeline
6. Add target dispatch tests
7. `just check` passes — no functional change

Each phase is independently deployable and all phases maintain backwards compatibility.

## Future: Package Extraction

Once the target architecture is stable, the codebase is naturally positioned for package extraction:

```
ghtml_core:    types.gleam, lexer.gleam, parser.gleam, codegen.gleam (shared utils only)
ghtml_lustre:  target/lustre.gleam, scanner.gleam, cache.gleam, watcher.gleam, CLI
ghtml:         Shim that re-exports ghtml_lustre.main()
```

This is NOT part of this spec. Noted here to show that the internal restructuring directly enables the eventual package split from the original plan.

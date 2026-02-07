# Module Coupling Analysis

## Question
How tightly coupled are the parser, codegen, and other modules? What needs to change for multi-target support?

## Findings

### Module Dependency Graph

```
types.gleam (0 internal deps)
    ↑
    │ (imports from)
    │
┌───┴───────────────┬──────────────┬──────────────┐
│                   │              │              │
parser.gleam    codegen.gleam  scanner.gleam   cache.gleam
(types only)    (types+cache)  (cache only)    (0 internal)
    │               │              │              ↑
    └───────────────┼──────────────┴──────────────┘
                    │
                    ↓
            ghtml.gleam (imports all)
                    ↑
                    │
            watcher.gleam (imports parser+codegen+scanner+cache)
```

### Parser (1713 lines) — Clean Extraction Target

**Imports:** `ghtml/types`, `gleam/int`, `gleam/list`, `gleam/option`, `gleam/result`, `gleam/string`

- Zero dependency on codegen, cache, scanner, or any framework
- Types used: Token, Node, Attr variants, Template, ParseError, Position, Span
- Contains both tokenize() and build_ast() — these are separate phases internally
- Can be split into lexer + parser without affecting other modules

### Codegen (783 lines) — Has Hidden Coupling

**Imports:** `ghtml/cache`, `ghtml/types`, `gleam/list`, `gleam/option`, `gleam/result`, `gleam/string`

Key coupling points:
1. **codegen → cache**: Calls `cache.generate_header()` to create the `// @generated` file header
2. **Lustre knowledge as strings**: No Lustre imports, but generates Lustre code via string constants:
   - `known_attributes`: 21 mappings like `#("class", "attribute.class")`
   - `boolean_attributes`: 6 HTML boolean attrs
   - Event mapping: `"click" → "event.on_click()"`, etc.
   - Framework calls: `html.div(...)`, `element(...)`, `keyed.fragment(...)`, `text(...)`

### Types (103 lines) — Fully Generic

**Imports:** `gleam/option` only

- Zero Lustre references
- Pure data types: Position, Span, Token, Attr, Node, Template
- Only Lustre-flavored thing: `EventAttr(prevent_default: Bool, stop_propagation: Bool)` — these are Lustre API concepts hardcoded as booleans

### Scanner (110 lines) — Independent

**Imports:** `ghtml/cache` (only for `is_generated()`), `gleam/io`, `gleam/list`, `gleam/string`, `simplifile`

- Works at file system level, no AST knowledge
- Dependency on cache is for checking if a `.gleam` file was generated (has `@generated` header)

### Cache (67 lines) — Leaf Module

**Imports:** `gleam/bit_array`, `gleam/crypto`, `gleam/list`, `gleam/string`, `simplifile`

- No internal module dependencies
- Pure functions: `hash_content()`, `needs_regeneration()`, `is_generated()`, `generate_header()`

### Watcher (209 lines) — Pipeline Orchestrator

**Imports:** `ghtml/cache`, `ghtml/codegen`, `ghtml/parser`, `ghtml/scanner`, plus OTP/process

- Mirrors ghtml.gleam's pipeline: scan → parse → generate → write
- Would need Target parameter threaded through

## Extraction Assessment

| Extraction | Difficulty | Blockers |
|------------|-----------|----------|
| types → standalone | Trivial | None (only depends on gleam/option) |
| parser → standalone | Easy | Only depends on types.gleam + stdlib |
| codegen → target dispatch | Medium | Must resolve cache dependency, separate shared utils |
| lexer from parser | Medium | Must identify tokenize() vs build_ast() boundaries in 1713-line file |

## Recommendation

1. **Phase 1 (AST):** Change EventAttr to generic modifiers. Low risk, affects types → parser → codegen.
2. **Phase 2 (Parser):** Split tokenize() into lexer.gleam. Medium effort but clean boundary exists.
3. **Phase 3 (Target):** Move codegen logic to target/lustre.gleam, keep shared utils in codegen.gleam. Resolve cache.generate_header() dependency (move header generation to shared or keep in target).

## Sources

- Direct analysis of source files in `/Users/burakpersonal/projects/ghtml/src/`
- Import analysis run on 2026-02-07

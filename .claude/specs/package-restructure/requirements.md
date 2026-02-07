# Requirements

Requirements use EARS (Easy Approach to Requirements Syntax).

## Patterns
- **Event-driven**: WHEN <trigger> THE <system> SHALL <response>
- **State-driven**: WHILE <condition> THE <system> SHALL <response>
- **Complex**: WHILE <condition> WHEN <trigger> THE <system> SHALL <response>

---

## Phase 1: AST Cleanup

### REQ-001: Generic Event Modifiers

WHEN the parser encounters event modifiers (e.g., `@click.prevent.stop`)
THE parser SHALL store modifiers as `List(String)` on `EventAttr`
AND NOT use framework-specific boolean fields

**Rationale:** Current `EventAttr` has `prevent_default: Bool` and `stop_propagation: Bool` — hardcoded to match Lustre's API. A generic modifier list allows any backend to interpret modifiers in its own way, and supports future modifiers without AST changes.

**Before:**
```gleam
EventAttr(event: String, handler: String, prevent_default: Bool, stop_propagation: Bool)
```

**After:**
```gleam
EventAttr(event: String, handler: String, modifiers: List(String))
// @click.prevent.stop={handler} → EventAttr("click", "handler", ["prevent", "stop"])
```

**Acceptance Criteria:**
- [ ] `EventAttr` type uses `modifiers: List(String)` instead of boolean flags
- [ ] Parser produces `["prevent"]` for `.prevent`, `["stop"]` for `.stop`, `["prevent", "stop"]` for `.prevent.stop`
- [ ] Lustre codegen interprets `"prevent"` as `event.prevent_default()` and `"stop"` as `event.stop_propagation()`
- [ ] All existing event modifier tests pass with updated assertions
- [ ] Modifier order is preserved from template syntax

---

### REQ-002: AST Type Naming Cleanup

WHEN types are used across multiple backends
THE type names SHALL be clear and consistent
AND avoid abbreviations that reduce readability

**Changes:**
| Current | New | Rationale |
|---------|-----|-----------|
| `Attr` | `Attribute` | Spell out for clarity |
| `StaticAttr` | `StaticAttribute` | Consistency |
| `DynamicAttr` | `DynamicAttribute` | Consistency |
| `EventAttr` | `EventAttribute` | Consistency |
| `BooleanAttr` | `BooleanAttribute` | Consistency |

**Acceptance Criteria:**
- [ ] All type names use full words (no abbreviations)
- [ ] All references updated across parser, codegen, and tests
- [ ] No functional changes — rename only

---

## Phase 2: Parser Split

### REQ-003: Extract Lexer Module

WHEN the project is compiled
THE system SHALL have a separate `src/ghtml/lexer.gleam` module
AND it SHALL contain all tokenization logic currently in `parser.gleam`

**Scope:** Extract `tokenize()` and all supporting tokenization functions from `parser.gleam` (currently 1713 lines combined) into a dedicated `lexer.gleam` module.

**Public API:**
```gleam
// ghtml/lexer.gleam
pub fn tokenize(input: String) -> Result(List(Token), List(ParseError))
```

**Acceptance Criteria:**
- [ ] `lexer.gleam` exists with `tokenize()` as public function
- [ ] All tokenization helper functions moved from `parser.gleam` to `lexer.gleam`
- [ ] `parser.gleam` imports and calls `lexer.tokenize()` instead of containing tokenization logic
- [ ] All existing tokenizer tests pass (re-pointed to `ghtml/lexer`)
- [ ] `parser.gleam` is significantly smaller (only AST construction)

---

### REQ-004: Parser Module Focus

WHEN `parser.parse()` is called
THE parser SHALL call `lexer.tokenize()` then `build_ast()` on the result
AND `parser.gleam` SHALL only contain AST construction logic

**Public API:**
```gleam
// ghtml/parser.gleam
pub fn parse(input: String) -> Result(Template, List(ParseError))
pub fn build_ast(tokens: List(Token)) -> Result(List(Node), List(ParseError))
```

**Acceptance Criteria:**
- [ ] `parser.gleam` no longer contains any tokenization code
- [ ] `parse()` delegates to `lexer.tokenize()` then `build_ast()`
- [ ] `build_ast()` remains public for direct use by tools that need token-level access
- [ ] All existing parser tests pass unchanged

---

## Phase 3: Target Architecture

### REQ-005: Target Type Definition

WHEN a codegen target is specified
THE system SHALL use a `Target` type to represent it
AND the type SHALL support future variants

```gleam
// In types.gleam
pub type Target {
  Lustre
  // Future: StringTree, String, Reactive
}
```

**Acceptance Criteria:**
- [ ] `Target` type defined in `types.gleam`
- [ ] `Lustre` variant exists as initial (and only) variant
- [ ] Type is extensible for future targets via new variants

---

### REQ-006: Target Directory Structure

WHEN the project is compiled
THE system SHALL have a `src/ghtml/target/` directory
AND each target SHALL have its own module file

```
src/ghtml/target/
  lustre.gleam    — Lustre-specific code generation
```

**Acceptance Criteria:**
- [ ] `src/ghtml/target/` directory exists
- [ ] `target/lustre.gleam` contains all Lustre-specific codegen logic
- [ ] Structure supports adding new target files without modifying existing ones

---

### REQ-007: Lustre Target Module

WHEN generating Lustre output
THE system SHALL use `target/lustre.gleam` for all Lustre-specific logic
AND produce identical output to the current implementation

**What moves to `target/lustre.gleam`:**
- `known_attributes` constant (HTML attr → `attribute.class` etc.)
- `boolean_attributes` constant
- Event handler mapping (`click → event.on_click` etc.)
- Event modifier interpretation (`"prevent" → event.prevent_default()` wrapping)
- Lustre import generation (`lustre/element`, `lustre/event`, etc.)
- Lustre-specific node generation (`html.div(...)`, `element("tag", ...)`, `keyed.fragment(...)`, etc.)

**Public API:**
```gleam
// ghtml/target/lustre.gleam
pub fn generate(template: Template, source_path: String, hash: String) -> String
```

**Acceptance Criteria:**
- [ ] All Lustre-specific constants and logic in `target/lustre.gleam`
- [ ] Output is byte-for-byte identical to current implementation for all templates
- [ ] All existing codegen tests pass without modification (re-pointed to target/lustre)
- [ ] No Lustre references remain in `codegen.gleam`

---

### REQ-008: Shared Codegen Utilities

WHEN generating code for any target
THE system SHALL provide shared utilities for common operations
AND utilities SHALL be target-agnostic

**Shared utilities (remain in `codegen.gleam` or new `codegen/utils.gleam`):**
- `escape_string()` — escape special characters for Gleam string literals
- `normalize_whitespace()` / `collapse_spaces()` — whitespace handling
- `is_blank()` — blank string check
- `void_elements` — HTML void element list (HTML spec, not framework-specific)
- `is_custom_element()` — tag contains hyphen (HTML spec)
- `is_void_element()` — tag is a void element

**AST analysis helpers (shared for all targets):**
- `template_has_events()` / `template_has_attrs()` / `template_has_each()` etc.
- These walk the AST to determine what features a template uses
- Each backend uses them to decide what imports/code to generate

**Acceptance Criteria:**
- [ ] Common utilities accessible to all target modules
- [ ] No Lustre-specific code in shared utilities
- [ ] All targets can use shared helpers for AST traversal and string manipulation

---

### REQ-009: Codegen Dispatcher

WHEN `codegen.generate()` is called
THE dispatcher SHALL route to the appropriate target module based on `Target`
AND the dispatcher SHALL be a thin routing layer with no codegen logic

```gleam
// ghtml/codegen.gleam
pub fn generate(template: Template, source_path: String, hash: String, target: Target) -> String {
  case target {
    Lustre -> lustre.generate(template, source_path, hash)
  }
}
```

**Acceptance Criteria:**
- [ ] `codegen.gleam` dispatches by `Target` value
- [ ] Dispatcher contains no codegen logic itself (only routing + shared utilities)
- [ ] Adding a new target requires only: new file in `target/`, new variant in `Target`, new case branch in dispatcher

---

### REQ-010: CLI Target Flag

WHEN user runs `gleam run -m ghtml -- --target=<name>`
THE CLI SHALL pass the target to the codegen pipeline
AND default to `lustre` if not specified

**Syntax:**
```bash
gleam run -m ghtml                      # Default: lustre
gleam run -m ghtml -- --target=lustre   # Explicit: lustre
gleam run -m ghtml -- --target=unknown  # Error with valid options
```

**Acceptance Criteria:**
- [ ] `--target` flag parsed by CLI
- [ ] Default value is `lustre`
- [ ] Invalid targets produce clear error message listing valid options
- [ ] Target flows through entire pipeline (CLI → generate → target module)
- [ ] Watch mode respects target flag

---

### REQ-011: Pipeline Integration

WHEN the generation pipeline runs
THE target selection SHALL flow from CLI through to codegen
AND watcher SHALL use the configured target

**Acceptance Criteria:**
- [ ] `ghtml.gleam` passes target to `codegen.generate()`
- [ ] `watcher.gleam` uses configured target for regeneration
- [ ] All generated files in a run use the same target
- [ ] `process_file()` signature updated to accept target

---

## Cross-Cutting

### REQ-012: Backwards Compatibility

WHILE no `--target` flag is specified
THE system SHALL behave identically to the current implementation
AND existing users SHALL require no changes

**Acceptance Criteria:**
- [ ] `gleam run -m ghtml` with no args produces identical output
- [ ] All examples build and produce same output
- [ ] No changes required in downstream projects
- [ ] `just check` passes

---

### REQ-013: Test Migration

WHEN the restructuring is complete
THE test suite SHALL cover the new module boundaries
AND maintain existing coverage

**Acceptance Criteria:**
- [ ] Lexer tests in `test/unit/parser/tokenizer_test.gleam` (or renamed) import from `ghtml/lexer`
- [ ] Parser tests in `test/unit/parser/ast_test.gleam` import from `ghtml/parser`
- [ ] Codegen tests in `test/unit/codegen/` work through dispatcher or directly test `target/lustre`
- [ ] New tests for target dispatch (correct routing, invalid target error)
- [ ] New tests for generic event modifiers in AST
- [ ] Integration tests verify end-to-end pipeline with target flag
- [ ] `just check` passes (all quality gates)

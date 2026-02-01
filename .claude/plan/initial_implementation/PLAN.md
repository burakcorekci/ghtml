# Lustre Template Generator for Gleam

## Goal

Build a Gleam preprocessor that converts `.lustre` template files into Gleam modules with Lustre `Element(msg)` render functions.

## File Convention

- Any `*.lustre` file in the project generates a corresponding `*.gleam` file in the same location
- `src/components/user_card.lustre` → `src/components/user_card.gleam`
- `src/pages/home.lustre` → `src/pages/home.gleam`

## Template Syntax

We're using a Svelte/Marko-inspired syntax:

### Metadata
- `@import(module/path.{type Type, Variant})` - Gleam imports
- `@params(name: Type, ...)` - Function parameters with types

### Interpolation
- `{expression}` - Any Gleam expression that evaluates to `String`
- `{{` - Escaped literal `{` character
- `}}` - Escaped literal `}` character

**Important:** All interpolated expressions in text content must evaluate to `String`. Use explicit conversion functions like `int.to_string()`, `float.to_string()`, etc.

### Control Flow
- `{#if condition}...{:else}...{/if}`
- `{#each list as item}...{/each}` or `{#each list as item, index}...{/each}`
- `{#case expr}{:Pattern}...{:Pattern(x)}...{/case}`

### HTML
- Standard HTML tags become `html.tag()` calls
- Custom element tags (containing `-`) become `element("tag-name", ...)` calls
- `class`, `id`, `href`, etc. become `attribute.x()`
- `{expr}` in attributes: `class={dynamic_class}`
- HTML comments `<!-- ... -->` are stripped from output

## Example

**Input:** `src/components/user_card.lustre`
```html
@import(app/models.{type User, type Role, Admin, Member})
@import(app/models.{type Post})
@import(gleam/option.{type Option, Some, None})
@import(gleam/int)

@params(
  user: User,
  posts: List(Post),
  show_email: Bool,
  on_save: fn() -> msg,
  on_email_change: fn(String) -> msg,
)

<article class="user-card">
  <h1>{user.name}</h1>

  {#case user.role}
    {:Admin}
      <sl-badge variant="primary">Admin</sl-badge>
    {:Member(since)}
      <sl-badge variant="neutral">Member since {int.to_string(since)}</sl-badge>
  {/case}

  {#if show_email}
    <sl-input type="email" value={user.email} @input={on_email_change} readonly></sl-input>
  {/if}

  <ul class="posts">
    {#each posts as post, i}
      <li class={row_class(i)}>{post.title}</li>
    {/each}
  </ul>

  <sl-button variant="primary" @click={on_save()}>
    <sl-icon slot="prefix" name="save"></sl-icon>
    Save Changes
  </sl-button>
</article>
```

**Output:** `src/components/user_card.gleam`
```gleam
// @generated from user_card.lustre
// @hash a1b2c3d4e5f6...
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import app/models.{type User, type Role, Admin, Member}
import app/models.{type Post}
import gleam/option.{type Option, Some, None}
import gleam/int
import gleam/list
import lustre/element.{type Element, element, text, none, keyed}
import lustre/element/html
import lustre/attribute
import lustre/event

pub fn render(
  user: User,
  posts: List(Post),
  show_email: Bool,
  on_save: fn() -> msg,
  on_email_change: fn(String) -> msg,
) -> Element(msg) {
  html.article([attribute.class("user-card")], [
    html.h1([], [text(user.name)]),
    case user.role {
      Admin -> element("sl-badge", [attribute.attribute("variant", "primary")], [text("Admin")])
      Member(since) -> element("sl-badge", [attribute.attribute("variant", "neutral")], [
        text("Member since "),
        text(int.to_string(since)),
      ])
    },
    case show_email {
      True -> element("sl-input", [
        attribute.type_("email"),
        attribute.value(user.email),
        event.on_input(on_email_change),
        attribute.attribute("readonly", ""),
      ], [])
      False -> none()
    },
    html.ul([attribute.class("posts")], [
      keyed(fn(post, i) {
        #(post.id, html.li([attribute.class(row_class(i))], [text(post.title)]))
      }, list.index_map(posts, fn(post, i) { #(post, i) }))
    ]),
    element("sl-button", [
      attribute.attribute("variant", "primary"),
      event.on_click(on_save()),
    ], [
      element("sl-icon", [
        attribute.attribute("slot", "prefix"),
        attribute.attribute("name", "save"),
      ], []),
      text("Save Changes"),
    ]),
  ])
}
```

## Project Structure
```
lustre_template_gen/
  src/
    lustre_template_gen.gleam      # CLI entry point
    lustre_template_gen/
      parser.gleam                  # Tokenizer + AST builder
      codegen.gleam                 # AST -> Gleam code
      types.gleam                   # Token, Node, Error types
      cache.gleam                   # Hash calculation + comparison
      scanner.gleam                 # Find .lustre files recursively
      watcher.gleam                 # File system watching
  gleam.toml
```

## Dependencies
```toml
[dependencies]
gleam_stdlib = "~> 0.34"
simplifile = "~> 2.0"
argv = "~> 1.0"
gleam_crypto = "~> 1.0"
gleam_erlang = "~> 0.25"      # For watch mode (process, timer)
```

## CLI Interface
```bash
gleam run -m lustre_template_gen              # Generate all (skips unchanged)
gleam run -m lustre_template_gen -- force     # Force regenerate all
gleam run -m lustre_template_gen -- watch     # Watch mode
gleam run -m lustre_template_gen -- clean     # Remove orphans only
```

## Type Definitions

### Token Types
```gleam
// types.gleam

/// Position in source file for error reporting
pub type Position {
  Position(line: Int, column: Int)
}

/// Span of source text
pub type Span {
  Span(start: Position, end: Position)
}

/// Parse error with location information
pub type ParseError {
  ParseError(span: Span, message: String)
}

/// Result type for parsing operations
pub type ParseResult(a) = Result(a, List(ParseError))

pub type Token {
  Import(content: String, span: Span)
  Params(params: List(#(String, String)), span: Span)
  HtmlOpen(tag: String, attrs: List(Attr), self_closing: Bool, span: Span)
  HtmlClose(tag: String, span: Span)
  Text(content: String, span: Span)
  Expr(content: String, span: Span)
  IfStart(condition: String, span: Span)
  Else(span: Span)
  IfEnd(span: Span)
  EachStart(collection: String, item: String, index: Option(String), span: Span)
  EachEnd(span: Span)
  CaseStart(expr: String, span: Span)
  CasePattern(pattern: String, span: Span)
  CaseEnd(span: Span)
  Comment(span: Span)  // HTML comments - will be stripped
}

pub type Attr {
  StaticAttr(name: String, value: String)
  DynamicAttr(name: String, expr: String)
  EventAttr(event: String, handler: String)  // handler is full expression including ()
  BooleanAttr(name: String)
}
```

### AST Node Types
```gleam
// types.gleam (continued)

/// AST Node representing parsed template structure
pub type Node {
  /// HTML/custom element with tag, attributes, and children
  Element(tag: String, attrs: List(Attr), children: List(Node), span: Span)

  /// Plain text content
  TextNode(content: String, span: Span)

  /// Gleam expression interpolation (must evaluate to String)
  ExprNode(expr: String, span: Span)

  /// Conditional rendering
  IfNode(
    condition: String,
    then_branch: List(Node),
    else_branch: List(Node),
    span: Span,
  )

  /// List iteration
  EachNode(
    collection: String,
    item: String,
    index: Option(String),
    body: List(Node),
    span: Span,
  )

  /// Pattern matching
  CaseNode(
    expr: String,
    branches: List(CaseBranch),
    span: Span,
  )

  /// Fragment containing multiple nodes (no wrapping element)
  Fragment(children: List(Node), span: Span)
}

pub type CaseBranch {
  CaseBranch(pattern: String, body: List(Node), span: Span)
}

/// Parsed template with metadata and body
pub type Template {
  Template(
    imports: List(String),
    params: List(#(String, String)),
    body: List(Node),
  )
}
```

## Key Requirements

### 1. File Discovery

Recursively find all `.lustre` files, excluding common directories:
```gleam
// scanner.gleam
import gleam/list
import gleam/string
import simplifile

const ignored_dirs = ["build", ".git", "node_modules", "_build", ".plan"]

pub fn find_lustre_files(root: String) -> List(String) {
  find_recursive(root, [])
}

fn find_recursive(dir: String, acc: List(String)) -> List(String) {
  case simplifile.read_directory(dir) {
    Ok(entries) -> {
      list.fold(entries, acc, fn(acc, entry) {
        case list.contains(ignored_dirs, entry) {
          True -> acc
          False -> {
            let path = dir <> "/" <> entry
            case simplifile.is_directory(path) {
              Ok(True) -> find_recursive(path, acc)
              _ -> case string.ends_with(entry, ".lustre") {
                True -> [path, ..acc]
                False -> acc
              }
            }
          }
        }
      })
    }
    Error(_) -> acc
  }
}

pub fn to_output_path(lustre_path: String) -> String {
  string.replace(lustre_path, ".lustre", ".gleam")
}

pub fn find_generated_files(root: String) -> List(String) {
  find_gleam_recursive(root, [])
}

fn find_gleam_recursive(dir: String, acc: List(String)) -> List(String) {
  case simplifile.read_directory(dir) {
    Ok(entries) -> {
      list.fold(entries, acc, fn(acc, entry) {
        case list.contains(ignored_dirs, entry) {
          True -> acc
          False -> {
            let path = dir <> "/" <> entry
            case simplifile.is_directory(path) {
              Ok(True) -> find_gleam_recursive(path, acc)
              _ -> case string.ends_with(entry, ".gleam") {
                True -> [path, ..acc]
                False -> acc
              }
            }
          }
        }
      })
    }
    Error(_) -> acc
  }
}
```

### 2. Hash-Based Caching

- Calculate SHA-256 hash of source `.lustre` file content
- Store hash in generated file header: `// @hash <hex_digest>`
- Skip regeneration if hashes match
```gleam
// cache.gleam
import gleam/crypto
import gleam/bit_array
import gleam/string
import gleam/list
import simplifile

pub fn hash_content(content: String) -> String {
  content
  |> bit_array.from_string()
  |> crypto.hash(crypto.Sha256, _)
  |> bit_array.base16_encode()
  |> string.lowercase()
}

pub fn extract_hash(generated_content: String) -> Result(String, Nil) {
  generated_content
  |> string.split("\n")
  |> list.find_map(fn(line) {
    case string.starts_with(line, "// @hash ") {
      True -> Ok(string.drop_start(line, 9) |> string.trim())
      False -> Error(Nil)
    }
  })
}

pub fn needs_regeneration(source_path: String, output_path: String) -> Bool {
  case simplifile.read(source_path), simplifile.read(output_path) {
    Ok(source), Ok(existing) -> {
      let current_hash = hash_content(source)
      case extract_hash(existing) {
        Ok(stored_hash) -> current_hash != stored_hash
        Error(_) -> True
      }
    }
    Ok(_), Error(_) -> True  // Output doesn't exist
    Error(_), _ -> False     // Source doesn't exist (shouldn't happen)
  }
}
```

### 3. Expression Parsing with Brace Balancing

Expressions can contain nested braces (e.g., `{some_fn({a: 1})}`). Use balanced parsing:
```gleam
// parser.gleam (partial)

/// Extract a Gleam expression, handling nested braces
/// Returns (expression_content, remaining_input)
fn extract_expression(
  input: String,
  depth: Int,
  acc: String,
  pos: Position,
) -> Result(#(String, String, Position), ParseError) {
  case string.pop_grapheme(input) {
    Error(_) ->
      Error(ParseError(
        Span(pos, pos),
        "Unexpected end of input while parsing expression",
      ))
    Ok(#("{", rest)) ->
      extract_expression(rest, depth + 1, acc <> "{", advance_pos(pos, "{"))
    Ok(#("}", rest)) ->
      case depth {
        0 -> Ok(#(acc, rest, advance_pos(pos, "}")))
        _ -> extract_expression(rest, depth - 1, acc <> "}", advance_pos(pos, "}"))
      }
    Ok(#("\"", rest)) -> {
      // Handle string literals to avoid counting braces inside strings
      case extract_string_literal(rest, "\"", advance_pos(pos, "\"")) {
        Ok(#(str, remaining, new_pos)) ->
          extract_expression(remaining, depth, acc <> "\"" <> str <> "\"", new_pos)
        Error(e) -> Error(e)
      }
    }
    Ok(#(char, rest)) ->
      extract_expression(rest, depth, acc <> char, advance_pos(pos, char))
  }
}

fn advance_pos(pos: Position, char: String) -> Position {
  case char {
    "\n" -> Position(pos.line + 1, 1)
    _ -> Position(pos.line, pos.column + 1)
  }
}

fn extract_string_literal(
  input: String,
  acc: String,
  pos: Position,
) -> Result(#(String, String, Position), ParseError) {
  case string.pop_grapheme(input) {
    Error(_) ->
      Error(ParseError(Span(pos, pos), "Unterminated string literal"))
    Ok(#("\\", rest)) -> {
      // Handle escape sequences
      case string.pop_grapheme(rest) {
        Ok(#(escaped, rest2)) ->
          extract_string_literal(rest2, acc <> "\\" <> escaped, advance_pos(advance_pos(pos, "\\"), escaped))
        Error(_) ->
          Error(ParseError(Span(pos, pos), "Unterminated escape sequence"))
      }
    }
    Ok(#("\"", rest)) -> Ok(#(acc, rest, advance_pos(pos, "\"")))
    Ok(#(char, rest)) ->
      extract_string_literal(rest, acc <> char, advance_pos(pos, char))
  }
}
```

### 4. Escape Sequences

Support `{{` and `}}` for literal braces:
```gleam
// parser.gleam (partial)

fn parse_text_content(input: String, pos: Position) -> #(String, String, Position) {
  parse_text_loop(input, "", pos)
}

fn parse_text_loop(
  input: String,
  acc: String,
  pos: Position,
) -> #(String, String, Position) {
  case input {
    // Escaped braces
    "{{" <> rest -> parse_text_loop(rest, acc <> "{", advance_pos(advance_pos(pos, "{"), "{"))
    "}}" <> rest -> parse_text_loop(rest, acc <> "}", advance_pos(advance_pos(pos, "}"), "}"))
    // Start of expression or control flow - stop here
    "{" <> _ -> #(acc, input, pos)
    // Start of HTML tag - stop here
    "<" <> _ -> #(acc, input, pos)
    // Regular character
    _ -> {
      case string.pop_grapheme(input) {
        Ok(#(char, rest)) -> parse_text_loop(rest, acc <> char, advance_pos(pos, char))
        Error(_) -> #(acc, input, pos)
      }
    }
  }
}
```

### 5. Whitespace Handling

Whitespace rules:
1. Collapse consecutive whitespace (spaces, tabs, newlines) to a single space
2. Trim leading/trailing whitespace around block-level elements
3. Preserve single spaces between inline content

```gleam
// codegen.gleam (partial)

/// Normalize whitespace in text content
fn normalize_whitespace(text: String) -> String {
  text
  |> string.to_graphemes()
  |> collapse_whitespace([])
  |> string.concat()
}

fn collapse_whitespace(chars: List(String), acc: List(String)) -> List(String) {
  case chars {
    [] -> list.reverse(acc)
    [c, ..rest] -> {
      case is_whitespace(c) {
        True -> {
          // Skip remaining whitespace, add single space
          let remaining = skip_whitespace(rest)
          collapse_whitespace(remaining, [" ", ..acc])
        }
        False -> collapse_whitespace(rest, [c, ..acc])
      }
    }
  }
}

fn is_whitespace(c: String) -> Bool {
  c == " " || c == "\t" || c == "\n" || c == "\r"
}

fn skip_whitespace(chars: List(String)) -> List(String) {
  case chars {
    [c, ..rest] if is_whitespace(c) -> skip_whitespace(rest)
    _ -> chars
  }
}

/// Check if text is only whitespace (should be skipped entirely)
fn is_blank(text: String) -> Bool {
  text
  |> string.to_graphemes()
  |> list.all(is_whitespace)
}
```

### 6. Custom Web Component Support

Detect custom elements by presence of hyphen in tag name:
```gleam
// codegen.gleam (partial)

fn is_custom_element(tag: String) -> Bool {
  string.contains(tag, "-")
}

fn generate_element(
  tag: String,
  attrs: List(Attr),
  children: List(Node),
  is_void: Bool,
) -> String {
  let attrs_code = generate_attrs(attrs, is_custom_element(tag))
  let children_code = case is_void {
    True -> ""
    False -> generate_children(children)
  }

  case is_custom_element(tag) {
    True -> "element(\"" <> tag <> "\", [" <> attrs_code <> "], [" <> children_code <> "])"
    False -> "html." <> tag <> "([" <> attrs_code <> "], [" <> children_code <> "])"
  }
}
```

### 7. Attribute Generation with Context

Process attributes during codegen when tag context is known:
```gleam
// codegen.gleam (partial)

/// Known Lustre attribute functions
const known_attributes = [
  #("class", "attribute.class"),
  #("id", "attribute.id"),
  #("href", "attribute.href"),
  #("src", "attribute.src"),
  #("alt", "attribute.alt"),
  #("type", "attribute.type_"),
  #("value", "attribute.value"),
  #("name", "attribute.name"),
  #("placeholder", "attribute.placeholder"),
  #("disabled", "attribute.disabled"),
  #("readonly", "attribute.readonly"),
  #("checked", "attribute.checked"),
  #("selected", "attribute.selected"),
  #("autofocus", "attribute.autofocus"),
  #("for", "attribute.for"),
  #("role", "attribute.role"),
  #("style", "attribute.style"),
]

/// Boolean attributes that take True/False
const boolean_attributes = [
  "disabled", "readonly", "checked", "selected", "autofocus", "required",
  "multiple", "hidden", "open", "novalidate",
]

fn generate_attr(attr: Attr, is_custom: Bool) -> String {
  case attr {
    StaticAttr(name, value) -> generate_static_attr(name, value, is_custom)
    DynamicAttr(name, expr) -> generate_dynamic_attr(name, expr, is_custom)
    EventAttr(event, handler) -> generate_event_attr(event, handler)
    BooleanAttr(name) -> generate_boolean_attr(name, is_custom)
  }
}

fn generate_static_attr(name: String, value: String, is_custom: Bool) -> String {
  case list.find(known_attributes, fn(pair) { pair.0 == name }) {
    Ok(#(_, func)) -> func <> "(\"" <> escape_string(value) <> "\")"
    Error(_) -> "attribute.attribute(\"" <> name <> "\", \"" <> escape_string(value) <> "\")"
  }
}

fn generate_dynamic_attr(name: String, expr: String, is_custom: Bool) -> String {
  case list.find(known_attributes, fn(pair) { pair.0 == name }) {
    Ok(#(_, func)) -> func <> "(" <> expr <> ")"
    Error(_) -> "attribute.attribute(\"" <> name <> "\", " <> expr <> ")"
  }
}

fn generate_boolean_attr(name: String, is_custom: Bool) -> String {
  case is_custom {
    True -> "attribute.attribute(\"" <> name <> "\", \"\")"
    False -> {
      case list.contains(boolean_attributes, name) {
        True -> {
          case list.find(known_attributes, fn(pair) { pair.0 == name }) {
            Ok(#(_, func)) -> func <> "(True)"
            Error(_) -> "attribute.attribute(\"" <> name <> "\", \"\")"
          }
        }
        False -> "attribute.attribute(\"" <> name <> "\", \"\")"
      }
    }
  }
}

fn generate_event_attr(event: String, handler: String) -> String {
  // handler is the full expression, including () if needed
  // e.g., "on_save()" for click, "on_change" for input
  let event_fn = case event {
    "click" -> "event.on_click"
    "input" -> "event.on_input"
    "change" -> "event.on_change"
    "submit" -> "event.on_submit"
    "blur" -> "event.on_blur"
    "focus" -> "event.on_focus"
    "keydown" -> "event.on_keydown"
    "keyup" -> "event.on_keyup"
    "keypress" -> "event.on_keypress"
    "mouseenter" -> "event.on_mouse_enter"
    "mouseleave" -> "event.on_mouse_leave"
    "mouseover" -> "event.on_mouse_over"
    "mouseout" -> "event.on_mouse_out"
    _ -> "event.on(\"" <> event <> "\", "
  }

  case event {
    // Standard events with dedicated functions
    "click" | "input" | "change" | "submit" | "blur" | "focus"
    | "keydown" | "keyup" | "keypress"
    | "mouseenter" | "mouseleave" | "mouseover" | "mouseout" ->
      event_fn <> "(" <> handler <> ")"
    // Custom events
    _ -> event_fn <> handler <> ")"
  }
}

fn escape_string(s: String) -> String {
  s
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
  |> string.replace("\n", "\\n")
  |> string.replace("\r", "\\r")
  |> string.replace("\t", "\\t")
}
```

### 8. Event Handler Convention

Event handlers in templates follow this convention:
- `@click={handler()}` - The expression is passed verbatim. For `on_click`, this should be a `msg` value (call the thunk).
- `@input={handler}` - For `on_input`, this should be a `fn(String) -> msg` (pass the function).

The template user is responsible for using the correct form. The generator passes the expression through unchanged.

```html
<!-- on_click expects msg, so call the thunk -->
<button @click={on_save()}>Save</button>

<!-- on_input expects fn(String) -> msg, so pass the function -->
<input @input={on_email_change} />

<!-- Custom handler with parameter -->
<button @click={handle_delete(item.id)}>Delete</button>
```

### 9. Void Elements
```gleam
// codegen.gleam

const void_elements = [
  "area", "base", "br", "col", "embed", "hr", "img", "input",
  "link", "meta", "param", "source", "track", "wbr",
]

fn is_void_element(tag: String) -> Bool {
  list.contains(void_elements, tag)
}
```

Self-closing syntax (`<div />`) is allowed for any element and is equivalent to `<div></div>`.
Void elements never have children regardless of syntax.

### 10. Pattern Matching

Case patterns are passed verbatim to Gleam. The template syntax directly mirrors Gleam's pattern syntax:
```html
{#case user.status}
  {:Ok(user)}
    <span>Welcome {user.name}</span>
  {:Error(msg)}
    <span class="error">{msg}</span>
  {:_}
    <span>Unknown</span>
{/case}
```

Complex patterns are supported:
```html
{#case result}
  {:Ok(#(name, age))}
    <span>{name} is {int.to_string(age)} years old</span>
  {:Error(_)}
    <span>Error occurred</span>
{/case}
```

Guard clauses are NOT supported (limitation of template syntax).

### 11. Smart Import Management

Only import modules when needed, and handle conflicts with user imports:
```gleam
// codegen.gleam (partial)

pub type UsedFeatures {
  UsedFeatures(
    uses_list: Bool,       // {#each} requires gleam/list
    uses_keyed: Bool,      // {#each} uses keyed for optimization
    uses_none: Bool,       // {#if} without else, or conditional rendering
    uses_fragment: Bool,   // Multiple root elements
    uses_event: Bool,      // Any @event handlers
  )
}

fn analyze_features(nodes: List(Node)) -> UsedFeatures {
  analyze_nodes(nodes, UsedFeatures(
    uses_list: False,
    uses_keyed: False,
    uses_none: False,
    uses_fragment: False,
    uses_event: False,
  ))
}

fn analyze_nodes(nodes: List(Node), features: UsedFeatures) -> UsedFeatures {
  list.fold(nodes, features, fn(f, node) {
    case node {
      EachNode(_, _, _, body, _) ->
        analyze_nodes(body, UsedFeatures(..f, uses_list: True, uses_keyed: True))
      IfNode(_, then_branch, else_branch, _) -> {
        let f = case else_branch {
          [] -> UsedFeatures(..f, uses_none: True)
          _ -> f
        }
        f |> analyze_nodes(then_branch, _) |> analyze_nodes(else_branch, _)
      }
      CaseNode(_, branches, _) ->
        list.fold(branches, f, fn(f, branch) { analyze_nodes(branch.body, f) })
      Element(_, attrs, children, _) -> {
        let f = case list.any(attrs, fn(a) {
          case a { EventAttr(_, _) -> True; _ -> False }
        }) {
          True -> UsedFeatures(..f, uses_event: True)
          False -> f
        }
        analyze_nodes(children, f)
      }
      Fragment(children, _) ->
        analyze_nodes(children, UsedFeatures(..f, uses_fragment: True))
      _ -> f
    }
  })
}

fn generate_imports(user_imports: List(String), features: UsedFeatures) -> String {
  let auto_imports = []

  // Add gleam/list if needed and not already imported
  let auto_imports = case features.uses_list && !has_import(user_imports, "gleam/list") {
    True -> ["import gleam/list", ..auto_imports]
    False -> auto_imports
  }

  // Build lustre imports based on usage
  let lustre_element_items = ["type Element", "element", "text"]
  let lustre_element_items = case features.uses_keyed {
    True -> ["keyed", ..lustre_element_items]
    False -> lustre_element_items
  }
  let lustre_element_items = case features.uses_none {
    True -> ["none", ..lustre_element_items]
    False -> lustre_element_items
  }
  let lustre_element_items = case features.uses_fragment {
    True -> ["fragment", ..lustre_element_items]
    False -> lustre_element_items
  }

  let lustre_imports = [
    "import lustre/element.{" <> string.join(lustre_element_items, ", ") <> "}",
    "import lustre/element/html",
    "import lustre/attribute",
  ]

  let lustre_imports = case features.uses_event {
    True -> list.append(lustre_imports, ["import lustre/event"])
    False -> lustre_imports
  }

  // User imports (check for conflicts with auto-imports)
  let user_import_lines = list.map(user_imports, fn(imp) { "import " <> imp })

  // Combine: auto-imports first, then lustre, then user imports
  [auto_imports, lustre_imports, user_import_lines]
  |> list.flatten()
  |> string.join("\n")
}

fn has_import(imports: List(String), module: String) -> Bool {
  list.any(imports, fn(imp) { string.starts_with(imp, module) })
}
```

### 12. Keyed Lists for Each Loops

For better performance with dynamic lists, `{#each}` generates keyed elements:
```gleam
// Generated code for {#each posts as post, i}
keyed(fn(pair) {
  let #(post, i) = pair
  #(post.id, html.li([attribute.class(row_class(i))], [text(post.title)]))
}, list.index_map(posts, fn(post, i) { #(post, i) }))
```

Note: The key must be provided by the user via a `.id` field or similar. If no obvious key exists, fall back to using index:
```gleam
// When no .id field is available, use index as key (less optimal)
keyed(fn(pair) {
  let #(item, i) = pair
  #(int.to_string(i), html.li([], [text(item)]))
}, list.index_map(items, fn(item, i) { #(item, i) }))
```

### 13. Orphan Cleanup

Find generated `.gleam` files whose source `.lustre` no longer exists:
```gleam
// scanner.gleam (continued)
import gleam/io

pub fn cleanup_orphans(root: String) -> Int {
  let removed = find_generated_files(root)
  |> list.filter_map(fn(gleam_path) {
    case simplifile.read(gleam_path) {
      Ok(content) -> {
        case is_generated(content) {
          True -> {
            let lustre_path = string.replace(gleam_path, ".gleam", ".lustre")
            case simplifile.is_file(lustre_path) {
              Ok(True) -> Error(Nil)  // Source exists, keep it
              _ -> {
                case simplifile.delete(gleam_path) {
                  Ok(_) -> {
                    io.println("✗ Removed orphan: " <> gleam_path)
                    Ok(gleam_path)
                  }
                  Error(_) -> Error(Nil)
                }
              }
            }
          }
          False -> Error(Nil)  // Not generated, leave alone
        }
      }
      Error(_) -> Error(Nil)
    }
  })

  list.length(removed)
}

fn is_generated(content: String) -> Bool {
  string.starts_with(content, "// @generated from ")
}
```

### 14. Watch Mode

Watch mode monitors `.lustre` files and regenerates on changes:
```gleam
// watcher.gleam
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/dict.{type Dict}
import gleam/io
import lustre_template_gen/scanner
import lustre_template_gen/cache

pub type WatcherMessage {
  Check
  Stop
}

pub type WatcherState {
  WatcherState(
    root: String,
    file_mtimes: Dict(String, Int),
  )
}

/// Start watching for file changes
pub fn start_watching(root: String) -> Subject(WatcherMessage) {
  let initial_state = WatcherState(
    root: root,
    file_mtimes: get_all_mtimes(root),
  )

  let assert Ok(subject) = actor.start(initial_state, handle_message)

  // Start the check loop
  schedule_check(subject)

  io.println("👀 Watching for changes... (Ctrl+C to stop)")
  subject
}

fn handle_message(
  message: WatcherMessage,
  state: WatcherState,
) -> actor.Next(WatcherMessage, WatcherState) {
  case message {
    Stop -> actor.Stop(process.Normal)
    Check -> {
      let new_state = check_for_changes(state)
      schedule_check(process.self())
      actor.continue(new_state)
    }
  }
}

fn schedule_check(subject: Subject(WatcherMessage)) {
  // Check every 500ms
  process.send_after(subject, 500, Check)
}

fn get_all_mtimes(root: String) -> Dict(String, Int) {
  scanner.find_lustre_files(root)
  |> list.filter_map(fn(path) {
    case get_mtime(path) {
      Ok(mtime) -> Ok(#(path, mtime))
      Error(_) -> Error(Nil)
    }
  })
  |> dict.from_list()
}

fn get_mtime(path: String) -> Result(Int, Nil) {
  case simplifile.file_info(path) {
    Ok(info) -> Ok(info.mtime_seconds)
    Error(_) -> Error(Nil)
  }
}

fn check_for_changes(state: WatcherState) -> WatcherState {
  let current_files = scanner.find_lustre_files(state.root)
  let current_mtimes = get_all_mtimes(state.root)

  // Check for new or modified files
  list.each(current_files, fn(path) {
    let should_process = case dict.get(state.file_mtimes, path) {
      Error(_) -> {
        io.println("📄 New file: " <> path)
        True
      }
      Ok(old_mtime) -> {
        case dict.get(current_mtimes, path) {
          Ok(new_mtime) if new_mtime != old_mtime -> {
            io.println("📝 Modified: " <> path)
            True
          }
          _ -> False
        }
      }
    }

    case should_process {
      True -> process_file(path)
      False -> Nil
    }
  })

  // Check for deleted files (orphan cleanup)
  dict.keys(state.file_mtimes)
  |> list.each(fn(old_path) {
    case list.contains(current_files, old_path) {
      False -> {
        io.println("🗑️  Deleted: " <> old_path)
        let gleam_path = scanner.to_output_path(old_path)
        case simplifile.delete(gleam_path) {
          Ok(_) -> io.println("✗ Removed: " <> gleam_path)
          Error(_) -> Nil
        }
      }
      True -> Nil
    }
  })

  WatcherState(..state, file_mtimes: current_mtimes)
}

fn process_file(source_path: String) {
  let output_path = scanner.to_output_path(source_path)

  case simplifile.read(source_path) {
    Ok(content) -> {
      let hash = cache.hash_content(content)
      case parser.parse(content) {
        Ok(template) -> {
          let gleam_code = codegen.generate(template, source_path, hash)
          case simplifile.write(output_path, gleam_code) {
            Ok(_) -> io.println("✓ " <> source_path <> " → " <> output_path)
            Error(e) -> io.println("✗ Error writing " <> output_path <> ": " <> string.inspect(e))
          }
        }
        Error(errors) -> {
          io.println("✗ Parse errors in " <> source_path <> ":")
          list.each(errors, fn(e) {
            io.println("  Line " <> int.to_string(e.span.start.line) <> ": " <> e.message)
          })
        }
      }
    }
    Error(e) -> io.println("✗ Error reading " <> source_path <> ": " <> string.inspect(e))
  }
}
```

### 15. Error Reporting

Provide helpful error messages with source locations:
```gleam
// parser.gleam (partial)

pub fn format_error(error: ParseError, source: String) -> String {
  let lines = string.split(source, "\n")
  let line_num = error.span.start.line
  let col = error.span.start.column

  let context = case list.at(lines, line_num - 1) {
    Ok(line) -> {
      let pointer = string.repeat(" ", col - 1) <> "^"
      "\n" <> line <> "\n" <> pointer
    }
    Error(_) -> ""
  }

  "Error at line " <> int.to_string(line_num)
  <> ", column " <> int.to_string(col)
  <> ": " <> error.message
  <> context
}

pub fn format_errors(errors: List(ParseError), source: String) -> String {
  errors
  |> list.map(fn(e) { format_error(e, source) })
  |> string.join("\n\n")
}
```

### 16. Generated File Header
```gleam
// @generated from <filename>.lustre
// @hash <sha256_hex>
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

// ... imports (conditional based on usage) ...

pub fn render(/* @params */) -> Element(msg) {
  // ... generated body ...
}
```

## Main Entry Point
```gleam
// lustre_template_gen.gleam
import argv
import gleam/io
import gleam/list
import gleam/int
import simplifile
import lustre_template_gen/scanner
import lustre_template_gen/cache
import lustre_template_gen/parser
import lustre_template_gen/codegen
import lustre_template_gen/watcher

pub fn main() {
  let args = argv.load().arguments
  let force = list.contains(args, "force")
  let clean_only = list.contains(args, "clean")
  let watch = list.contains(args, "watch")

  case clean_only {
    True -> {
      let count = scanner.cleanup_orphans(".")
      io.println("Cleaned up " <> int.to_string(count) <> " orphaned files")
    }
    False -> {
      // Initial generation
      let stats = generate_all(".", force)
      io.println("")
      io.println("Generated: " <> int.to_string(stats.generated))
      io.println("Skipped (unchanged): " <> int.to_string(stats.skipped))
      io.println("Errors: " <> int.to_string(stats.errors))

      // Cleanup orphans
      let orphans = scanner.cleanup_orphans(".")
      case orphans > 0 {
        True -> io.println("Removed orphans: " <> int.to_string(orphans))
        False -> Nil
      }

      // Watch mode
      case watch {
        True -> {
          let _subject = watcher.start_watching(".")
          // Keep the process alive
          process.sleep_forever()
        }
        False -> Nil
      }
    }
  }
}

pub type GenerationStats {
  GenerationStats(generated: Int, skipped: Int, errors: Int)
}

fn generate_all(root: String, force: Bool) -> GenerationStats {
  scanner.find_lustre_files(root)
  |> list.fold(GenerationStats(0, 0, 0), fn(stats, source_path) {
    let output_path = scanner.to_output_path(source_path)

    case force || cache.needs_regeneration(source_path, output_path) {
      True -> {
        case process_file(source_path, output_path) {
          Ok(_) -> GenerationStats(..stats, generated: stats.generated + 1)
          Error(_) -> GenerationStats(..stats, errors: stats.errors + 1)
        }
      }
      False -> {
        io.println("· " <> source_path <> " (unchanged)")
        GenerationStats(..stats, skipped: stats.skipped + 1)
      }
    }
  })
}

fn process_file(source_path: String, output_path: String) -> Result(Nil, String) {
  case simplifile.read(source_path) {
    Ok(content) -> {
      let hash = cache.hash_content(content)
      case parser.parse(content) {
        Ok(template) -> {
          let gleam_code = codegen.generate(template, source_path, hash)
          case simplifile.write(output_path, gleam_code) {
            Ok(_) -> {
              io.println("✓ " <> source_path <> " → " <> output_path)
              Ok(Nil)
            }
            Error(e) -> {
              io.println("✗ Error writing " <> output_path)
              Error("Write error")
            }
          }
        }
        Error(errors) -> {
          io.println("✗ Parse errors in " <> source_path <> ":")
          io.println(parser.format_errors(errors, content))
          Error("Parse error")
        }
      }
    }
    Error(_) -> {
      io.println("✗ Error reading " <> source_path)
      Error("Read error")
    }
  }
}
```

## Attribute Mapping Reference

| Template | Standard HTML | Custom Element |
|----------|---------------|----------------|
| `class="x"` | `attribute.class("x")` | `attribute.class("x")` |
| `class={x}` | `attribute.class(x)` | `attribute.class(x)` |
| `id="x"` | `attribute.id("x")` | `attribute.id("x")` |
| `href="x"` | `attribute.href("x")` | `attribute.href("x")` |
| `type="x"` | `attribute.type_("x")` | `attribute.type_("x")` |
| `value={x}` | `attribute.value(x)` | `attribute.value(x)` |
| `variant="x"` | `attribute.attribute("variant", "x")` | `attribute.attribute("variant", "x")` |
| `disabled` | `attribute.disabled(True)` | `attribute.attribute("disabled", "")` |
| `readonly` | `attribute.readonly(True)` | `attribute.attribute("readonly", "")` |
| `data-foo="x"` | `attribute.attribute("data-foo", "x")` | `attribute.attribute("data-foo", "x")` |
| `aria-label="x"` | `attribute.attribute("aria-label", "x")` | `attribute.attribute("aria-label", "x")` |
| `@click={h()}` | `event.on_click(h())` | `event.on_click(h())` |
| `@input={h}` | `event.on_input(h)` | `event.on_input(h)` |
| `@custom={h}` | `event.on("custom", h)` | `event.on("custom", h)` |

## Summary of Design Decisions

1. **All interpolated values must be `String`** - No automatic type conversion
2. **Escape `{{` and `}}`** for literal braces in text
3. **Whitespace is collapsed** to single spaces, trimmed around blocks
4. **Event handlers are passed verbatim** - User controls calling convention
5. **Patterns are passed verbatim** to Gleam (no guards supported)
6. **HTML comments are stripped** from output
7. **Imports are conditional** based on feature usage
8. **`{#each}` uses keyed** for performance
9. **Boolean attrs differ** between standard HTML and custom elements
10. **Watch mode polls** at 500ms intervals using mtime comparison

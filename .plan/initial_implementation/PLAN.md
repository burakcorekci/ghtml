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
- `{expression}` - Any Gleam expression, passed through verbatim

### Control Flow
- `{#if condition}...{:else}...{/if}`
- `{#each list as item}...{/each}` or `{#each list as item, index}...{/each}`
- `{#case expr}{:Pattern}...{:Pattern(x)}...{/case}`

### HTML
- Standard HTML tags become `html.tag()` calls
- Custom element tags (containing `-`) become `element("tag-name", ...)` calls
- `class`, `id`, `href`, etc. become `attribute.x()`
- `{expr}` in attributes: `class={dynamic_class}`

## Example

**Input:** `src/components/user_card.lustre`
```html
@import(app/models.{type User, type Role, Admin, Member})
@import(gleam/option.{type Option, Some, None})
@import(gleam/int)

@params(
  user: User,
  posts: List(Post),
  show_email: Bool,
  on_save: fn() -> msg,
)

<article class="user-card">
  <h1>{user.name}</h1>
  
  {#case user.role}
    {:Admin}
      <sl-badge variant="primary">Admin</sl-badge>
    {:Member(since)}
      <sl-badge variant="neutral">Member since {since}</sl-badge>
  {/case}
  
  {#if show_email}
    <sl-input type="email" value={user.email} readonly></sl-input>
  {/if}
  
  <ul class="posts">
    {#each posts as post, i}
      <li class={row_class(i)}>{post.title}</li>
    {/each}
  </ul>
  
  <sl-button variant="primary" @click={on_save}>
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
import gleam/option.{type Option, Some, None}
import gleam/int
import gleam/list
import lustre/element.{type Element, element, text, none, fragment}
import lustre/element/html
import lustre/attribute
import lustre/event

pub fn render(
  user: User,
  posts: List(Post),
  show_email: Bool,
  on_save: fn() -> msg,
) -> Element(msg) {
  html.article([attribute.class("user-card")], [
    html.h1([], [text(user.name)]),
    case user.role {
      Admin -> element("sl-badge", [attribute.attribute("variant", "primary")], [text("Admin")])
      Member(since) -> element("sl-badge", [attribute.attribute("variant", "neutral")], [
        text("Member since "),
        text(since),
      ])
    },
    case show_email {
      True -> element("sl-input", [
        attribute.type_("email"),
        attribute.value(user.email),
        attribute.attribute("readonly", ""),
      ], [])
      False -> none()
    },
    html.ul([attribute.class("posts")], [
      fragment(list.index_map(posts, fn(post, i) {
        html.li([attribute.class(row_class(i))], [text(post.title)])
      }))
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
      parser.gleam                  # Tokenizer + AST
      codegen.gleam                 # AST -> Gleam code
      types.gleam                   # Token, Node types
      cache.gleam                   # Hash calculation + comparison
      scanner.gleam                 # Find .lustre files recursively
  gleam.toml
```

## Dependencies
```toml
[dependencies]
gleam_stdlib = "~> 0.34"
simplifile = "~> 2.0"
argv = "~> 1.0"
gleam_crypto = "~> 1.0"
```

## CLI Interface
```bash
gleam run -m lustre_template_gen              # Generate all (skips unchanged)
gleam run -m lustre_template_gen -- force     # Force regenerate all
gleam run -m lustre_template_gen -- watch     # Watch mode
gleam run -m lustre_template_gen -- clean     # Remove orphans only
```

## Key Requirements

### 1. File Discovery

Recursively find all `.lustre` files, excluding common directories:
```gleam
// scanner.gleam
const ignored_dirs = ["build", ".git", "node_modules", "_build"]

pub fn find_lustre_files(root: String) -> List(String) {
  find_recursive(root, [])
}

fn find_recursive(dir: String, acc: List(String)) -> List(String) {
  case simplifile.read_directory(dir) {
    Ok(entries) -> {
      entries
      |> list.filter(fn(name) { !list.contains(ignored_dirs, name) })
      |> list.fold(acc, fn(acc, entry) {
        let path = dir <> "/" <> entry
        case simplifile.is_directory(path) {
          Ok(True) -> find_recursive(path, acc)
          _ if string.ends_with(entry, ".lustre") -> [path, ..acc]
          _ -> acc
        }
      })
    }
    Error(_) -> acc
  }
}

pub fn to_output_path(lustre_path: String) -> String {
  string.replace(lustre_path, ".lustre", ".gleam")
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
    Ok(_), Error(_) -> True
    Error(_), _ -> False
  }
}
```

### 3. Custom Web Component Support

Detect custom elements by presence of hyphen in tag name:
```gleam
fn is_custom_element(tag: String) -> Bool {
  string.contains(tag, "-")
}

fn tag_to_lustre(tag: String, attrs: String, children: String) -> String {
  case is_custom_element(tag) {
    True -> "element(\"" <> tag <> "\", [" <> attrs <> "], [" <> children <> "])"
    False -> "html." <> tag <> "([" <> attrs <> "], [" <> children <> "])"
  }
}
```

### 4. Event Handling

- `@click={handler}` → `event.on_click(handler())`
- `@input={handler}` → `event.on_input(handler)`
- `@change={handler}` → `event.on_change(handler)`

### 5. Orphan Cleanup

Find generated `.gleam` files whose source `.lustre` no longer exists:
```gleam
pub fn cleanup_orphans(root: String) {
  find_generated_files(root)
  |> list.each(fn(gleam_path) {
    case simplifile.read(gleam_path) {
      Ok(content) -> {
        case is_generated(content) {
          True -> {
            let lustre_path = string.replace(gleam_path, ".gleam", ".lustre")
            case simplifile.is_file(lustre_path) {
              Ok(True) -> Nil
              _ -> {
                let _ = simplifile.delete(gleam_path)
                io.println("✗ Removed orphan: " <> gleam_path)
              }
            }
          }
          False -> Nil  // Not generated, leave alone
        }
      }
      Error(_) -> Nil
    }
  })
}

fn is_generated(content: String) -> Bool {
  string.starts_with(content, "// @generated from ")
}
```

### 6. Void Elements
```gleam
const void_elements = [
  "area", "base", "br", "col", "embed", "hr", "img", "input",
  "link", "meta", "param", "source", "track", "wbr",
]
```

## Token Types
```gleam
pub type Token {
  Import(String)
  Params(List(#(String, String)))
  Html(tag: String, attrs: List(Attr), self_closing: Bool)
  HtmlClose(String)
  Text(String)
  Expr(String)
  IfStart(String)
  Else
  IfEnd
  EachStart(item: String, index: Option(String), collection: String)
  EachEnd
  CaseStart(String)
  CasePattern(String)
  CaseEnd
}

pub type Attr {
  StaticAttr(name: String, value: String)
  DynamicAttr(name: String, expr: String)
  EventAttr(event: String, handler: String)
  BooleanAttr(name: String)
}
```

## Attribute Mapping

| Template | Standard HTML | Custom Element |
|----------|---------------|----------------|
| `class="x"` | `attribute.class("x")` | `attribute.class("x")` |
| `class={x}` | `attribute.class(x)` | `attribute.class(x)` |
| `id="x"` | `attribute.id("x")` | `attribute.id("x")` |
| `href="x"` | `attribute.href("x")` | `attribute.href("x")` |
| `type="x"` | `attribute.type_("x")` | `attribute.type_("x")` |
| `variant="x"` | `attribute.attribute("variant", "x")` | `attribute.attribute("variant", "x")` |
| `disabled` | `attribute.disabled(True)` | `attribute.attribute("disabled", "")` |
| `@click={h}` | `event.on_click(h())` | `event.on_click(h())` |

## Generated File Header
```gleam
// @generated from <filename>.lustre
// @hash <sha256_hex>
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import gleam/list
import lustre/element.{type Element, element, text, none, fragment}
import lustre/element/html
import lustre/attribute
import lustre/event
// ... user @imports ...

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
import lustre_template_gen/scanner
import lustre_template_gen/cache
import lustre_template_gen/parser
import lustre_template_gen/codegen

pub fn main() {
  let force = list.contains(argv.load().arguments, "force")
  let clean_only = list.contains(argv.load().arguments, "clean")
  
  case clean_only {
    True -> scanner.cleanup_orphans(".")
    False -> {
      scanner.find_lustre_files(".")
      |> list.each(fn(source_path) {
        let output_path = scanner.to_output_path(source_path)
        
        case force || cache.needs_regeneration(source_path, output_path) {
          True -> {
            let assert Ok(content) = simplifile.read(source_path)
            let hash = cache.hash_content(content)
            let ast = parser.parse(content)
            let gleam_code = codegen.generate(ast, source_path, hash)
            let assert Ok(_) = simplifile.write(output_path, gleam_code)
            io.println("✓ " <> source_path <> " → " <> output_path)
          }
          False -> io.println("· " <> source_path <> " (unchanged)")
        }
      })
      
      scanner.cleanup_orphans(".")
    }
  }
}
```

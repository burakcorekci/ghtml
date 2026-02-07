//// Lustre target backend for code generation.
////
//// This module contains the Lustre-specific code generation logic,
//// producing Gleam source that uses the Lustre framework's element types.
//// It uses shared utilities from ghtml/codegen for common operations.

import ghtml/cache
import ghtml/codegen
import ghtml/types.{
  type Attribute, type CaseBranch, type Node, type Template, BooleanAttribute,
  CaseNode, DynamicAttribute, EachNode, Element, EventAttribute, ExprNode,
  Fragment, IfNode, StaticAttribute, TextNode,
}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

/// Known HTML attributes that have dedicated Lustre functions
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
  #("width", "attribute.width"),
  #("height", "attribute.height"),
  #("title", "attribute.title"),
  #("target", "attribute.target"),
  #("rel", "attribute.rel"),
  #("action", "attribute.action"),
  #("method", "attribute.method"),
  #("required", "attribute.required"),
]

/// Boolean attributes that should use dedicated functions for standard elements
const boolean_attributes = [
  "disabled", "readonly", "checked", "selected", "autofocus", "required",
]

/// Generate Gleam code from a parsed template using the Lustre target
pub fn generate(template: Template, source_path: String, hash: String) -> String {
  let filename = codegen.extract_filename(source_path)
  let header = cache.generate_header(filename, hash)
  let imports = generate_imports(template)
  let body = generate_function(template)

  header <> "\n" <> imports <> "\n\n" <> body <> "\n"
}

/// Generate import statements for the generated module
fn generate_imports(template: Template) -> String {
  let needs_attrs = codegen.template_has_attrs(template.body)
  let needs_events = codegen.template_has_events(template.body)
  let needs_none = codegen.template_needs_none(template.body)
  let needs_fragment = codegen.template_needs_fragment(template.body)
  let needs_each = codegen.template_has_each(template.body)
  let needs_each_index = codegen.template_has_each_with_index(template.body)
  let needs_element = codegen.template_has_custom_elements(template.body)
  let needs_html = codegen.template_has_html_elements(template.body)
  let needs_text = codegen.template_needs_text(template.body)
  let user_imports = template.imports

  // Build element import items list
  let element_items = ["type Element"]
  let element_items = case needs_text {
    True -> list.append(element_items, ["text"])
    False -> element_items
  }
  let element_items = case needs_element {
    True -> list.append(element_items, ["element"])
    False -> element_items
  }
  let element_items = case needs_none {
    True -> list.append(element_items, ["none"])
    False -> element_items
  }
  let element_items = case needs_fragment {
    True -> list.append(element_items, ["fragment"])
    False -> element_items
  }

  let element_import =
    "import lustre/element.{" <> string.join(element_items, ", ") <> "}"

  let base_imports = case needs_html {
    True -> element_import <> "\nimport lustre/element/html"
    False -> element_import
  }

  // Add keyed import if needed for each loops
  let base_imports = case needs_each {
    True -> base_imports <> "\nimport lustre/element/keyed"
    False -> base_imports
  }

  // Add attribute/event imports
  let imports = case needs_attrs, needs_events {
    True, True ->
      base_imports <> "\nimport lustre/attribute\nimport lustre/event"
    True, False -> base_imports <> "\nimport lustre/attribute"
    False, True -> base_imports <> "\nimport lustre/event"
    False, False -> base_imports
  }

  // Add list import if needed for each and not already imported by user
  let imports = case
    needs_each && !codegen.has_user_import(user_imports, "gleam/list")
  {
    True -> imports <> "\nimport gleam/list"
    False -> imports
  }

  // Add int import if needed for index and not already imported by user
  let imports = case
    needs_each_index && !codegen.has_user_import(user_imports, "gleam/int")
  {
    True -> imports <> "\nimport gleam/int"
    False -> imports
  }

  // Add user imports
  let imports = case user_imports {
    [] -> imports
    _ -> {
      let user_import_lines =
        list.map(user_imports, fn(imp) { "import " <> imp })
        |> string.join("\n")
      imports <> "\n" <> user_import_lines
    }
  }

  imports
}

/// Generate the main render function
fn generate_function(template: Template) -> String {
  let params = generate_params(template.params)

  case list.length(template.body) {
    0 -> "pub fn render(" <> params <> ") -> Element(msg) {\n  fragment([])\n}"
    1 -> {
      let body =
        generate_node_inline(
          list.first(template.body)
          |> result.unwrap(TextNode(
            "",
            types.point_span(types.start_position()),
          )),
        )
      "pub fn render(" <> params <> ") -> Element(msg) {\n  " <> body <> "\n}"
    }
    _ -> {
      // Multiple roots need fragment with multi-line formatting
      let children =
        template.body
        |> list.filter_map(fn(node) {
          let code = generate_node_inline(node)
          case string.trim(code) {
            "" -> Error(Nil)
            _ -> Ok("    " <> code)
          }
        })
        |> string.join(",\n")
      "pub fn render("
      <> params
      <> ") -> Element(msg) {\n  fragment([\n"
      <> children
      <> ",\n  ])\n}"
    }
  }
}

/// Generate function parameters from template params (single line, no trailing comma)
fn generate_params(params: List(#(String, String))) -> String {
  params
  |> list.map(fn(p) { p.0 <> ": " <> p.1 })
  |> string.join(", ")
}

/// Generate code for a single AST node (inline, no indentation)
fn generate_node_inline(node: Node) -> String {
  case node {
    Element(tag, attrs, children, _) ->
      generate_element_inline(tag, attrs, children)
    TextNode(content, _) -> generate_text_inline(content)
    ExprNode(expr, _) -> "text(" <> expr <> ")"
    IfNode(condition, then_branch, else_branch, _) ->
      generate_if_node_inline(condition, then_branch, else_branch)
    EachNode(collection, item, index, body, _) ->
      generate_each_node_inline(collection, item, index, body)
    CaseNode(expr, branches, _) -> generate_case_node_inline(expr, branches)
    Fragment(children, _) -> generate_fragment_inline(children)
  }
}

/// Generate code for an HTML element (inline format)
fn generate_element_inline(
  tag: String,
  attrs: List(Attribute),
  children: List(Node),
) -> String {
  let is_custom = codegen.is_custom_element(tag)
  let is_void = codegen.is_void_element(tag)
  let attrs_code = generate_attrs(attrs, is_custom)

  case is_custom {
    True -> {
      let children_code = generate_children_inline(children)
      "element(\""
      <> tag
      <> "\", "
      <> attrs_code
      <> ", ["
      <> children_code
      <> "])"
    }
    False -> {
      case is_void {
        // Void elements in Lustre v5 take only 1 argument (attributes)
        True -> "html." <> tag <> "(" <> attrs_code <> ")"
        False -> {
          let children_code = generate_children_inline(children)
          "html." <> tag <> "(" <> attrs_code <> ", [" <> children_code <> "])"
        }
      }
    }
  }
}

/// Generate code for a list of attributes
fn generate_attrs(attrs: List(Attribute), is_custom: Bool) -> String {
  case list.is_empty(attrs) {
    True -> "[]"
    False -> {
      let attr_strings =
        attrs
        |> list.map(fn(attr) { generate_attr(attr, is_custom) })
        |> string.join(", ")
      "[" <> attr_strings <> "]"
    }
  }
}

/// Generate code for a single attribute
fn generate_attr(attr: Attribute, is_custom: Bool) -> String {
  case attr {
    StaticAttribute(name, value) -> generate_static_attr(name, value)
    DynamicAttribute(name, expr) -> generate_dynamic_attr(name, expr)
    EventAttribute(event, handler, modifiers) ->
      generate_event_attr(event, handler, modifiers)
    BooleanAttribute(name) -> generate_boolean_attr(name, is_custom)
  }
}

/// Generate code for a static attribute
fn generate_static_attr(name: String, value: String) -> String {
  case find_attr_function(name) {
    Ok(func) -> func <> "(\"" <> codegen.escape_string(value) <> "\")"
    Error(_) ->
      "attribute.attribute(\""
      <> name
      <> "\", \""
      <> codegen.escape_string(value)
      <> "\")"
  }
}

/// Generate code for a dynamic attribute
fn generate_dynamic_attr(name: String, expr: String) -> String {
  case find_attr_function(name) {
    Ok(func) -> func <> "(" <> expr <> ")"
    Error(_) -> "attribute.attribute(\"" <> name <> "\", " <> expr <> ")"
  }
}

/// Generate code for a boolean attribute
fn generate_boolean_attr(name: String, is_custom: Bool) -> String {
  case is_custom {
    True -> "attribute.attribute(\"" <> name <> "\", \"\")"
    False -> {
      case list.contains(boolean_attributes, name) {
        True -> {
          case find_attr_function(name) {
            Ok(func) -> func <> "(True)"
            Error(_) -> "attribute.attribute(\"" <> name <> "\", \"\")"
          }
        }
        False -> "attribute.attribute(\"" <> name <> "\", \"\")"
      }
    }
  }
}

/// Generate code for an event handler attribute
fn generate_event_attr(
  event: String,
  handler: String,
  modifiers: List(String),
) -> String {
  let base = case event {
    "click" -> "event.on_click(" <> handler <> ")"
    "input" -> "event.on_input(" <> handler <> ")"
    "change" -> "event.on_change(" <> handler <> ")"
    "submit" -> "event.on_submit(" <> handler <> ")"
    "blur" -> "event.on_blur(" <> handler <> ")"
    "focus" -> "event.on_focus(" <> handler <> ")"
    "keydown" -> "event.on_keydown(" <> handler <> ")"
    "keyup" -> "event.on_keyup(" <> handler <> ")"
    "keypress" -> "event.on_keypress(" <> handler <> ")"
    "mouseenter" -> "event.on_mouse_enter(" <> handler <> ")"
    "mouseleave" -> "event.on_mouse_leave(" <> handler <> ")"
    "mouseover" -> "event.on_mouse_over(" <> handler <> ")"
    "mouseout" -> "event.on_mouse_out(" <> handler <> ")"
    _ -> {
      // Strip "on:" prefix for custom event handlers (e.g., @on:keydown -> keydown)
      let event_name = case string.starts_with(event, "on:") {
        True -> string.drop_start(event, 3)
        False -> event
      }
      "event.on(\"" <> event_name <> "\", " <> handler <> ")"
    }
  }
  apply_event_modifiers(base, modifiers)
}

/// Apply event modifiers in order, wrapping with appropriate Lustre functions
fn apply_event_modifiers(base: String, modifiers: List(String)) -> String {
  list.fold(modifiers, base, fn(acc, modifier) {
    case modifier {
      "prevent" -> "event.prevent_default(" <> acc <> ")"
      "stop" -> "event.stop_propagation(" <> acc <> ")"
      _ -> acc
    }
  })
}

/// Find the Lustre function for a known attribute
fn find_attr_function(name: String) -> Result(String, Nil) {
  list.find_map(known_attributes, fn(pair) {
    case pair.0 == name {
      True -> Ok(pair.1)
      False -> Error(Nil)
    }
  })
}

/// Generate code for a text node with whitespace normalization (inline)
fn generate_text_inline(content: String) -> String {
  let normalized = codegen.normalize_whitespace(content)
  case codegen.is_blank(normalized) {
    True -> ""
    False -> "text(\"" <> codegen.escape_string(normalized) <> "\")"
  }
}

/// Generate code for a list of children nodes (inline, comma-separated)
fn generate_children_inline(children: List(Node)) -> String {
  children
  |> list.filter_map(fn(child) {
    let code = generate_node_inline(child)
    case string.trim(code) {
      "" -> Error(Nil)
      _ -> Ok(code)
    }
  })
  |> string.join(", ")
}

/// Generate code for an if node (case expression with True/False branches)
fn generate_if_node_inline(
  condition: String,
  then_branch: List(Node),
  else_branch: List(Node),
) -> String {
  let then_code = generate_branch_content(then_branch)
  let else_code = case else_branch {
    [] -> "none()"
    _ -> generate_branch_content(else_branch)
  }

  "case "
  <> condition
  <> " { True -> "
  <> then_code
  <> " False -> "
  <> else_code
  <> " }"
}

/// Generate code for branch content (single node or fragment for multiple)
fn generate_branch_content(nodes: List(Node)) -> String {
  case nodes {
    [] -> "none()"
    [single] -> generate_node_inline(single)
    multiple -> {
      let children = generate_children_inline(multiple)
      "fragment([" <> children <> "])"
    }
  }
}

/// Generate code for an each node (keyed with list.map or list.index_map)
fn generate_each_node_inline(
  collection: String,
  item: String,
  index: option.Option(String),
  body: List(Node),
) -> String {
  let body_code = generate_branch_content(body)

  case index {
    None -> {
      // No index: list.map with keyed.fragment
      "keyed.fragment(list.map("
      <> collection
      <> ", fn("
      <> item
      <> ") { #("
      <> item
      <> ".id, "
      <> body_code
      <> ") }))"
    }
    Some(idx) -> {
      // With index: list.index_map with keyed.fragment
      "keyed.fragment(list.index_map("
      <> collection
      <> ", fn("
      <> item
      <> ", "
      <> idx
      <> ") { #(int.to_string("
      <> idx
      <> "), "
      <> body_code
      <> ") }))"
    }
  }
}

/// Generate code for a case node
fn generate_case_node_inline(expr: String, branches: List(CaseBranch)) -> String {
  let branches_code =
    branches
    |> list.map(fn(branch: CaseBranch) {
      let body_code = generate_branch_content(branch.body)
      branch.pattern <> " -> " <> body_code
    })
    |> string.join(" ")

  "case " <> expr <> " { " <> branches_code <> " }"
}

/// Generate code for a fragment node
fn generate_fragment_inline(children: List(Node)) -> String {
  let children_code = generate_children_inline(children)
  "fragment([" <> children_code <> "])"
}

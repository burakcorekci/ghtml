//// Gleam code generator from parsed templates.
////
//// Transforms the parsed AST into valid Gleam source code that uses the
//// Lustre library to render HTML elements. Generated code is formatted
//// to be compliant with `gleam format`.

import ghtml/cache
import ghtml/types.{
  type Attr, type CaseBranch, type Node, type Template, BooleanAttr, CaseNode,
  DynamicAttr, EachNode, Element, EventAttr, ExprNode, Fragment, IfNode,
  StaticAttr, TextNode,
}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

/// List of HTML void elements that cannot have children
const void_elements = [
  "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta",
  "param", "source", "track", "wbr",
]

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

/// Generate Gleam code from a parsed template
pub fn generate(template: Template, source_path: String, hash: String) -> String {
  let filename = extract_filename(source_path)
  let header = cache.generate_header(filename, hash)
  let imports = generate_imports(template)
  let body = generate_function(template)

  header <> "\n" <> imports <> "\n\n" <> body <> "\n"
}

/// Extract the filename from a full path
fn extract_filename(path: String) -> String {
  path
  |> string.split("/")
  |> list.last()
  |> result.unwrap("unknown.ghtml")
}

/// Generate import statements for the generated module
fn generate_imports(template: Template) -> String {
  let needs_attrs = template_has_attrs(template.body)
  let needs_events = template_has_events(template.body)
  let needs_none = template_needs_none(template.body)
  let needs_fragment = template_needs_fragment(template.body)
  let needs_each = template_has_each(template.body)
  let needs_each_index = template_has_each_with_index(template.body)
  let needs_element = template_has_custom_elements(template.body)
  let needs_html = template_has_html_elements(template.body)
  let needs_text = template_needs_text(template.body)
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
    needs_each && !has_user_import(user_imports, "gleam/list")
  {
    True -> imports <> "\nimport gleam/list"
    False -> imports
  }

  // Add int import if needed for index and not already imported by user
  let imports = case
    needs_each_index && !has_user_import(user_imports, "gleam/int")
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

/// Check if template needs `none` import (if without else)
fn template_needs_none(nodes: List(Node)) -> Bool {
  list.any(nodes, node_needs_none)
}

/// Check if a node or its children need `none`
fn node_needs_none(node: Node) -> Bool {
  case node {
    IfNode(_, then_branch, else_branch, _) ->
      case else_branch {
        [] -> True
        _ ->
          list.any(then_branch, node_needs_none)
          || list.any(else_branch, node_needs_none)
      }
    EachNode(_, _, _, body, _) -> list.any(body, node_needs_none)
    CaseNode(_, branches, _) ->
      list.any(branches, fn(b: CaseBranch) { list.any(b.body, node_needs_none) })
    Element(_, _, children, _) -> list.any(children, node_needs_none)
    Fragment(children, _) -> list.any(children, node_needs_none)
    _ -> False
  }
}

/// Check if template needs `fragment` import (multiple roots or multiple children in branches)
fn template_needs_fragment(nodes: List(Node)) -> Bool {
  // Multiple root nodes need fragment
  list.length(nodes) > 1 || list.any(nodes, node_needs_fragment)
}

/// Check if a node or its children need `fragment`
fn node_needs_fragment(node: Node) -> Bool {
  case node {
    IfNode(_, then_branch, else_branch, _) -> {
      // Fragment needed if multiple children in either branch
      let then_needs = list.length(then_branch) > 1
      let else_needs = list.length(else_branch) > 1
      then_needs
      || else_needs
      || list.any(then_branch, node_needs_fragment)
      || list.any(else_branch, node_needs_fragment)
    }
    EachNode(_, _, _, body, _) -> {
      // Fragment needed if multiple children in body
      list.length(body) > 1 || list.any(body, node_needs_fragment)
    }
    CaseNode(_, branches, _) -> {
      // Fragment needed if any branch has multiple children
      list.any(branches, fn(b: CaseBranch) {
        list.length(b.body) > 1 || list.any(b.body, node_needs_fragment)
      })
    }
    Element(_, _, children, _) -> list.any(children, node_needs_fragment)
    Fragment(_, _) -> True
    _ -> False
  }
}

/// Check if user has imported a specific module
fn has_user_import(imports: List(String), module: String) -> Bool {
  list.any(imports, fn(imp) {
    string.starts_with(imp, module <> ".")
    || string.starts_with(imp, module <> "{")
    || imp == module
  })
}

/// Check if template needs `text` import
fn template_needs_text(nodes: List(Node)) -> Bool {
  list.any(nodes, node_needs_text)
}

/// Check if a node or its children need `text`
fn node_needs_text(node: Node) -> Bool {
  case node {
    TextNode(_, _) -> True
    ExprNode(_, _) -> True
    IfNode(_, then_branch, else_branch, _) ->
      list.any(then_branch, node_needs_text)
      || list.any(else_branch, node_needs_text)
    EachNode(_, _, _, body, _) -> list.any(body, node_needs_text)
    CaseNode(_, branches, _) ->
      list.any(branches, fn(b: CaseBranch) { list.any(b.body, node_needs_text) })
    Element(_, _, children, _) -> list.any(children, node_needs_text)
    Fragment(children, _) -> list.any(children, node_needs_text)
  }
}

/// Check if any nodes have each nodes
fn template_has_each(nodes: List(Node)) -> Bool {
  list.any(nodes, node_has_each)
}

/// Check if a node or its children have each nodes
fn node_has_each(node: Node) -> Bool {
  case node {
    EachNode(_, _, _, body, _) -> True || list.any(body, node_has_each)
    IfNode(_, then_branch, else_branch, _) ->
      list.any(then_branch, node_has_each)
      || list.any(else_branch, node_has_each)
    CaseNode(_, branches, _) ->
      list.any(branches, fn(b: CaseBranch) { list.any(b.body, node_has_each) })
    Element(_, _, children, _) -> list.any(children, node_has_each)
    Fragment(children, _) -> list.any(children, node_has_each)
    _ -> False
  }
}

/// Check if any nodes have each nodes with index
fn template_has_each_with_index(nodes: List(Node)) -> Bool {
  list.any(nodes, node_has_each_with_index)
}

/// Check if a node or its children have each nodes with index
fn node_has_each_with_index(node: Node) -> Bool {
  case node {
    EachNode(_, _, Some(_), body, _) ->
      True || list.any(body, node_has_each_with_index)
    EachNode(_, _, None, body, _) -> list.any(body, node_has_each_with_index)
    IfNode(_, then_branch, else_branch, _) ->
      list.any(then_branch, node_has_each_with_index)
      || list.any(else_branch, node_has_each_with_index)
    CaseNode(_, branches, _) ->
      list.any(branches, fn(b: CaseBranch) {
        list.any(b.body, node_has_each_with_index)
      })
    Element(_, _, children, _) -> list.any(children, node_has_each_with_index)
    Fragment(children, _) -> list.any(children, node_has_each_with_index)
    _ -> False
  }
}

/// Check if any nodes have attributes
fn template_has_attrs(nodes: List(Node)) -> Bool {
  list.any(nodes, node_has_attrs)
}

/// Check if a node or its children have attributes
fn node_has_attrs(node: Node) -> Bool {
  case node {
    Element(_, attrs, children, _) ->
      has_non_event_attrs(attrs) || list.any(children, node_has_attrs)
    IfNode(_, then_branch, else_branch, _) ->
      list.any(then_branch, node_has_attrs)
      || list.any(else_branch, node_has_attrs)
    EachNode(_, _, _, body, _) -> list.any(body, node_has_attrs)
    CaseNode(_, branches, _) ->
      list.any(branches, fn(b: CaseBranch) { list.any(b.body, node_has_attrs) })
    Fragment(children, _) -> list.any(children, node_has_attrs)
    _ -> False
  }
}

/// Check if attrs list contains non-event attributes
fn has_non_event_attrs(attrs: List(Attr)) -> Bool {
  list.any(attrs, fn(attr) {
    case attr {
      StaticAttr(_, _) -> True
      DynamicAttr(_, _) -> True
      BooleanAttr(_) -> True
      EventAttr(_, _, _, _) -> False
    }
  })
}

/// Check if any nodes have event attributes
fn template_has_events(nodes: List(Node)) -> Bool {
  list.any(nodes, node_has_events)
}

/// Check if a node or its children have events
fn node_has_events(node: Node) -> Bool {
  case node {
    Element(_, attrs, children, _) ->
      has_event_attrs(attrs) || list.any(children, node_has_events)
    IfNode(_, then_branch, else_branch, _) ->
      list.any(then_branch, node_has_events)
      || list.any(else_branch, node_has_events)
    EachNode(_, _, _, body, _) -> list.any(body, node_has_events)
    CaseNode(_, branches, _) ->
      list.any(branches, fn(b: CaseBranch) { list.any(b.body, node_has_events) })
    Fragment(children, _) -> list.any(children, node_has_events)
    _ -> False
  }
}

/// Check if attrs list contains event attributes
fn has_event_attrs(attrs: List(Attr)) -> Bool {
  list.any(attrs, fn(attr) {
    case attr {
      EventAttr(_, _, _, _) -> True
      _ -> False
    }
  })
}

/// Check if a tag is a custom element (contains a hyphen)
fn is_custom_element(tag: String) -> Bool {
  string.contains(tag, "-")
}

/// Check if any nodes have custom elements
fn template_has_custom_elements(nodes: List(Node)) -> Bool {
  list.any(nodes, node_has_custom_elements)
}

/// Check if a node or its children have custom elements
fn node_has_custom_elements(node: Node) -> Bool {
  case node {
    Element(tag, _, children, _) ->
      is_custom_element(tag) || list.any(children, node_has_custom_elements)
    IfNode(_, then_branch, else_branch, _) ->
      list.any(then_branch, node_has_custom_elements)
      || list.any(else_branch, node_has_custom_elements)
    EachNode(_, _, _, body, _) -> list.any(body, node_has_custom_elements)
    CaseNode(_, branches, _) ->
      list.any(branches, fn(b: CaseBranch) {
        list.any(b.body, node_has_custom_elements)
      })
    Fragment(children, _) -> list.any(children, node_has_custom_elements)
    _ -> False
  }
}

/// Check if any nodes have standard HTML elements (non-custom)
fn template_has_html_elements(nodes: List(Node)) -> Bool {
  list.any(nodes, node_has_html_elements)
}

/// Check if a node or its children have standard HTML elements
fn node_has_html_elements(node: Node) -> Bool {
  case node {
    Element(tag, _, children, _) ->
      !is_custom_element(tag) || list.any(children, node_has_html_elements)
    IfNode(_, then_branch, else_branch, _) ->
      list.any(then_branch, node_has_html_elements)
      || list.any(else_branch, node_has_html_elements)
    EachNode(_, _, _, body, _) -> list.any(body, node_has_html_elements)
    CaseNode(_, branches, _) ->
      list.any(branches, fn(b: CaseBranch) {
        list.any(b.body, node_has_html_elements)
      })
    Fragment(children, _) -> list.any(children, node_has_html_elements)
    _ -> False
  }
}

/// Check if a tag is a void element (no children allowed)
fn is_void_element(tag: String) -> Bool {
  list.contains(void_elements, tag)
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
  attrs: List(Attr),
  children: List(Node),
) -> String {
  let is_custom = is_custom_element(tag)
  let is_void = is_void_element(tag)
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
fn generate_attrs(attrs: List(Attr), is_custom: Bool) -> String {
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
fn generate_attr(attr: Attr, is_custom: Bool) -> String {
  case attr {
    StaticAttr(name, value) -> generate_static_attr(name, value)
    DynamicAttr(name, expr) -> generate_dynamic_attr(name, expr)
    EventAttr(event, handler, prevent_default, stop_propagation) ->
      generate_event_attr(event, handler, prevent_default, stop_propagation)
    BooleanAttr(name) -> generate_boolean_attr(name, is_custom)
  }
}

/// Generate code for a static attribute
fn generate_static_attr(name: String, value: String) -> String {
  case find_attr_function(name) {
    Ok(func) -> func <> "(\"" <> escape_string(value) <> "\")"
    Error(_) ->
      "attribute.attribute(\""
      <> name
      <> "\", \""
      <> escape_string(value)
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
  prevent_default: Bool,
  stop_propagation: Bool,
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
  let base = case prevent_default {
    True -> "event.prevent_default(" <> base <> ")"
    False -> base
  }
  case stop_propagation {
    True -> "event.stop_propagation(" <> base <> ")"
    False -> base
  }
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
  let normalized = normalize_whitespace(content)
  case is_blank(normalized) {
    True -> ""
    False -> "text(\"" <> escape_string(normalized) <> "\")"
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

/// Escape special characters in a string for Gleam code
fn escape_string(s: String) -> String {
  s
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
  |> string.replace("\n", "\\n")
  |> string.replace("\r", "\\r")
  |> string.replace("\t", "\\t")
}

/// Normalize whitespace by collapsing multiple spaces/tabs to single spaces
/// Newlines are preserved (they will be escaped later)
fn normalize_whitespace(text: String) -> String {
  text
  |> string.to_graphemes()
  |> collapse_spaces(False, [])
  |> list.reverse()
  |> string.concat()
}

/// Helper function to collapse consecutive spaces/tabs (not newlines)
fn collapse_spaces(
  chars: List(String),
  saw_space: Bool,
  acc: List(String),
) -> List(String) {
  case chars {
    [] -> acc
    [c, ..rest] -> {
      case c {
        // Spaces and tabs get collapsed
        " " | "\t" ->
          case saw_space {
            True -> collapse_spaces(rest, True, acc)
            False -> collapse_spaces(rest, True, [" ", ..acc])
          }
        // Newlines and carriage returns are preserved (will be escaped later)
        "\n" | "\r" -> collapse_spaces(rest, False, [c, ..acc])
        // Regular characters reset the space tracking
        _ -> collapse_spaces(rest, False, [c, ..acc])
      }
    }
  }
}

/// Check if a string is blank (empty or only whitespace)
fn is_blank(text: String) -> Bool {
  string.trim(text) == ""
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

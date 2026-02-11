//// Nakai target backend for code generation.
////
//// This module contains the Nakai-specific code generation logic,
//// producing Gleam source that uses Nakai's HTML types for server-side rendering.
//// Nakai is SSR-only — event attributes are skipped.

import ghtml/cache
import ghtml/codegen_utils
import ghtml/types.{
  type Attribute, type CaseBranch, type Node, type Template, BooleanAttribute,
  CaseNode, DynamicAttribute, EachNode, Element, EventAttribute, ExprNode,
  Fragment, IfNode, StaticAttribute, TextNode,
}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

/// Known HTML attributes that have dedicated Nakai functions
const known_attributes = [
  #("class", "attr.class"),
  #("id", "attr.id"),
  #("href", "attr.href"),
  #("src", "attr.src"),
  #("alt", "attr.alt"),
  #("type", "attr.type_"),
  #("value", "attr.value"),
  #("name", "attr.name"),
  #("placeholder", "attr.placeholder"),
  #("for", "attr.for"),
  #("role", "attr.role"),
  #("style", "attr.style"),
  #("width", "attr.width"),
  #("height", "attr.height"),
  #("title", "attr.title"),
  #("target", "attr.target"),
  #("rel", "attr.rel"),
  #("action", "attr.action"),
  #("method", "attr.method"),
]

/// Boolean attributes that use zero-argument functions in Nakai
const boolean_attributes = [
  "disabled", "readonly", "checked", "selected", "autofocus",
]

/// Generate Gleam code from a parsed template using the Nakai target
pub fn generate(template: Template, source_path: String, hash: String) -> String {
  let filename = codegen_utils.extract_filename(source_path)
  let header = cache.generate_header(filename, hash)
  let imports = generate_imports(template)
  let body = generate_function(template)

  header <> "\n" <> imports <> "\n\n" <> body <> "\n"
}

/// Generate import statements for the generated module
fn generate_imports(template: Template) -> String {
  let needs_attrs = codegen_utils.template_has_attrs(template.body)
  let needs_each = codegen_utils.template_has_each(template.body)
  let needs_each_index =
    codegen_utils.template_has_each_with_index(template.body)
  let user_imports = template.imports

  let imports = "import nakai/html"

  // Add attr import if needed
  let imports = case needs_attrs {
    True -> imports <> "\nimport nakai/attr"
    False -> imports
  }

  // Add list import if needed for each and not already imported by user
  let imports = case
    needs_each && !codegen_utils.has_user_import(user_imports, "gleam/list")
  {
    True -> imports <> "\nimport gleam/list"
    False -> imports
  }

  // Add int import if needed for index and not already imported by user
  let imports = case
    needs_each_index
    && !codegen_utils.has_user_import(user_imports, "gleam/int")
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
    0 -> "pub fn render(" <> params <> ") -> html.Node {\n  html.Nothing\n}"
    1 -> {
      let body =
        generate_node_inline(
          list.first(template.body)
          |> result.unwrap(TextNode(
            "",
            types.point_span(types.start_position()),
          )),
        )
      "pub fn render(" <> params <> ") -> html.Node {\n  " <> body <> "\n}"
    }
    _ -> {
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
      <> ") -> html.Node {\n  html.Fragment([\n"
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
    ExprNode(expr, _) -> "html.Text(" <> expr <> ")"
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
  case codegen_utils.is_component(tag) {
    True -> generate_component_inline(tag, attrs, children)
    False -> generate_html_element_inline(tag, attrs, children)
  }
}

/// Generate code for a component call (PascalCase tag → module.render(...))
fn generate_component_inline(
  tag: String,
  attrs: List(Attribute),
  children: List(Node),
) -> String {
  let module_name = codegen_utils.pascal_to_snake(tag)
  let args = generate_component_args(attrs, children)
  module_name <> ".render(" <> args <> ")"
}

/// Generate labeled arguments for a component call
fn generate_component_args(
  attrs: List(Attribute),
  children: List(Node),
) -> String {
  let attr_args =
    attrs
    |> list.filter_map(fn(attr) {
      case attr {
        StaticAttribute(name, value) ->
          Ok(
            codegen_utils.attr_name_to_gleam(name)
            <> ": \""
            <> codegen_utils.escape_string(value)
            <> "\"",
          )
        DynamicAttribute(name, expr) ->
          Ok(codegen_utils.attr_name_to_gleam(name) <> ": " <> expr)
        BooleanAttribute(name) ->
          Ok(codegen_utils.attr_name_to_gleam(name) <> ": True")
        EventAttribute(_, _, _) -> Error(Nil)
      }
    })

  let all_args = case children {
    [] -> attr_args
    _ -> {
      let children_code = generate_children_inline(children)
      list.append(attr_args, ["children: [" <> children_code <> "]"])
    }
  }

  string.join(all_args, ", ")
}

/// Generate code for a standard HTML element (inline format)
fn generate_html_element_inline(
  tag: String,
  attrs: List(Attribute),
  children: List(Node),
) -> String {
  let is_custom = codegen_utils.is_custom_element(tag)
  let is_void = codegen_utils.is_void_element(tag)
  // Filter out event attributes — Nakai is SSR-only
  let attrs = list.filter(attrs, fn(a) { !is_event_attr(a) })
  let attrs_code = generate_attrs(attrs, is_custom)

  case is_custom {
    True -> {
      case is_void {
        True -> "html.LeafElement(\"" <> tag <> "\", " <> attrs_code <> ")"
        False -> {
          let children_code = generate_children_inline(children)
          "html.Element(\""
          <> tag
          <> "\", "
          <> attrs_code
          <> ", ["
          <> children_code
          <> "])"
        }
      }
    }
    False -> {
      case is_void {
        True -> "html." <> tag <> "(" <> attrs_code <> ")"
        False -> {
          let children_code = generate_children_inline(children)
          "html." <> tag <> "(" <> attrs_code <> ", [" <> children_code <> "])"
        }
      }
    }
  }
}

/// Check if an attribute is an event attribute
fn is_event_attr(attr: Attribute) -> Bool {
  case attr {
    EventAttribute(_, _, _) -> True
    _ -> False
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
    EventAttribute(_, _, _) -> ""
    BooleanAttribute(name) -> generate_boolean_attr(name, is_custom)
  }
}

/// Generate code for a static attribute
fn generate_static_attr(name: String, value: String) -> String {
  case find_attr_function(name) {
    Ok(func) -> func <> "(\"" <> codegen_utils.escape_string(value) <> "\")"
    Error(_) ->
      "attr.Attr(\""
      <> name
      <> "\", \""
      <> codegen_utils.escape_string(value)
      <> "\")"
  }
}

/// Generate code for a dynamic attribute
fn generate_dynamic_attr(name: String, expr: String) -> String {
  case find_attr_function(name) {
    Ok(func) -> func <> "(" <> expr <> ")"
    Error(_) -> "attr.Attr(\"" <> name <> "\", " <> expr <> ")"
  }
}

/// Generate code for a boolean attribute
fn generate_boolean_attr(name: String, is_custom: Bool) -> String {
  case is_custom {
    True -> "attr.Attr(\"" <> name <> "\", \"\")"
    False -> {
      case list.contains(boolean_attributes, name) {
        True -> {
          // Nakai boolean attrs take no arguments
          case find_boolean_function(name) {
            Ok(func) -> func <> "()"
            Error(_) -> "attr.Attr(\"" <> name <> "\", \"\")"
          }
        }
        False -> "attr.Attr(\"" <> name <> "\", \"\")"
      }
    }
  }
}

/// Find the Nakai function for a known attribute
fn find_attr_function(name: String) -> Result(String, Nil) {
  list.find_map(known_attributes, fn(pair) {
    case pair.0 == name {
      True -> Ok(pair.1)
      False -> Error(Nil)
    }
  })
}

/// Find the Nakai boolean function for a known boolean attribute
fn find_boolean_function(name: String) -> Result(String, Nil) {
  case name {
    "disabled" -> Ok("attr.disabled")
    "readonly" -> Ok("attr.readonly")
    "checked" -> Ok("attr.checked")
    "selected" -> Ok("attr.selected")
    "autofocus" -> Ok("attr.autofocus")
    _ -> Error(Nil)
  }
}

/// Generate code for a text node with whitespace normalization (inline)
fn generate_text_inline(content: String) -> String {
  let normalized = codegen_utils.normalize_whitespace(content)
  case codegen_utils.is_blank(normalized) {
    True -> ""
    False -> "html.Text(\"" <> codegen_utils.escape_string(normalized) <> "\")"
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
    [] -> "html.Nothing"
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
    [] -> "html.Nothing"
    [single] -> generate_node_inline(single)
    multiple -> {
      let children = generate_children_inline(multiple)
      "html.Fragment([" <> children <> "])"
    }
  }
}

/// Generate code for an each node (Fragment with list.map or list.index_map)
fn generate_each_node_inline(
  collection: String,
  item: String,
  index: option.Option(String),
  body: List(Node),
) -> String {
  let body_code = generate_branch_content(body)

  case index {
    None -> {
      "html.Fragment(list.map("
      <> collection
      <> ", fn("
      <> item
      <> ") { "
      <> body_code
      <> " }))"
    }
    Some(idx) -> {
      "html.Fragment(list.index_map("
      <> collection
      <> ", fn("
      <> item
      <> ", "
      <> idx
      <> ") { "
      <> body_code
      <> " }))"
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
  "html.Fragment([" <> children_code <> "])"
}

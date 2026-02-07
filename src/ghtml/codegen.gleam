//// Shared code generation utilities.
////
//// This module contains target-agnostic helpers used by all code generation
//// backends. Target-specific code lives in ghtml/target/ modules.

import ghtml/types.{
  type Attribute, type CaseBranch, type Node, BooleanAttribute, CaseNode,
  DynamicAttribute, EachNode, Element, EventAttribute, Fragment, IfNode,
  StaticAttribute,
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

/// Extract the filename from a full path
pub fn extract_filename(path: String) -> String {
  path
  |> string.split("/")
  |> list.last()
  |> result.unwrap("unknown.ghtml")
}

/// Check if template needs `none` import (if without else)
pub fn template_needs_none(nodes: List(Node)) -> Bool {
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
pub fn template_needs_fragment(nodes: List(Node)) -> Bool {
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
pub fn has_user_import(imports: List(String), module: String) -> Bool {
  list.any(imports, fn(imp) {
    string.starts_with(imp, module <> ".")
    || string.starts_with(imp, module <> "{")
    || imp == module
  })
}

/// Check if template needs `text` import
pub fn template_needs_text(nodes: List(Node)) -> Bool {
  list.any(nodes, node_needs_text)
}

/// Check if a node or its children need `text`
fn node_needs_text(node: Node) -> Bool {
  case node {
    types.TextNode(_, _) -> True
    types.ExprNode(_, _) -> True
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
pub fn template_has_each(nodes: List(Node)) -> Bool {
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
pub fn template_has_each_with_index(nodes: List(Node)) -> Bool {
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
pub fn template_has_attrs(nodes: List(Node)) -> Bool {
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
fn has_non_event_attrs(attrs: List(Attribute)) -> Bool {
  list.any(attrs, fn(attr) {
    case attr {
      StaticAttribute(_, _) -> True
      DynamicAttribute(_, _) -> True
      BooleanAttribute(_) -> True
      EventAttribute(_, _, _) -> False
    }
  })
}

/// Check if any nodes have event attributes
pub fn template_has_events(nodes: List(Node)) -> Bool {
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
fn has_event_attrs(attrs: List(Attribute)) -> Bool {
  list.any(attrs, fn(attr) {
    case attr {
      EventAttribute(_, _, _) -> True
      _ -> False
    }
  })
}

/// Check if a tag is a custom element (contains a hyphen)
pub fn is_custom_element(tag: String) -> Bool {
  string.contains(tag, "-")
}

/// Check if any nodes have custom elements
pub fn template_has_custom_elements(nodes: List(Node)) -> Bool {
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
pub fn template_has_html_elements(nodes: List(Node)) -> Bool {
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
pub fn is_void_element(tag: String) -> Bool {
  list.contains(void_elements, tag)
}

/// Escape special characters in a string for Gleam code
pub fn escape_string(s: String) -> String {
  s
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
  |> string.replace("\n", "\\n")
  |> string.replace("\r", "\\r")
  |> string.replace("\t", "\\t")
}

/// Normalize whitespace by collapsing multiple spaces/tabs to single spaces
/// Newlines are preserved (they will be escaped later)
pub fn normalize_whitespace(text: String) -> String {
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
pub fn is_blank(text: String) -> Bool {
  string.trim(text) == ""
}

import ghtml/types.{
  BooleanAttribute, CaseBranch, CaseNode, DynamicAttribute, EachNode, Element,
  EventAttribute, ExprNode, Fragment, IfNode, Lustre, ParseError, Position, Span,
  StaticAttribute, Template, TextNode, point_span, start_position,
  target_from_string, valid_target_names,
}
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should

pub fn position_creation_test() {
  let pos = Position(line: 1, column: 5)
  should.equal(pos.line, 1)
  should.equal(pos.column, 5)
}

pub fn span_creation_test() {
  let start = Position(line: 1, column: 1)
  let end = Position(line: 1, column: 10)
  let span = Span(start: start, end: end)
  should.equal(span.start.line, 1)
  should.equal(span.end.column, 10)
}

pub fn parse_error_creation_test() {
  let span =
    Span(
      start: Position(line: 5, column: 3),
      end: Position(line: 5, column: 10),
    )
  let error = ParseError(span: span, message: "Unexpected token")
  should.equal(error.message, "Unexpected token")
  should.equal(error.span.start.line, 5)
}

pub fn static_attr_test() {
  let attr = StaticAttribute(name: "class", value: "container")
  should.be_true(is_static_attr(attr))
  let StaticAttribute(name, value) = attr
  should.equal(name, "class")
  should.equal(value, "container")
}

fn is_static_attr(attr: types.Attribute) -> Bool {
  case attr {
    StaticAttribute(_, _) -> True
    _ -> False
  }
}

pub fn dynamic_attr_test() {
  let attr = DynamicAttribute(name: "class", expr: "my_class")
  should.be_true(is_dynamic_attr(attr))
  let DynamicAttribute(name, expr) = attr
  should.equal(name, "class")
  should.equal(expr, "my_class")
}

fn is_dynamic_attr(attr: types.Attribute) -> Bool {
  case attr {
    DynamicAttribute(_, _) -> True
    _ -> False
  }
}

pub fn event_attr_test() {
  let attr =
    EventAttribute(event: "click", handler: "handle_click()", modifiers: [])
  should.be_true(is_event_attr(attr))
  let EventAttribute(event, handler, _) = attr
  should.equal(event, "click")
  should.equal(handler, "handle_click()")
}

fn is_event_attr(attr: types.Attribute) -> Bool {
  case attr {
    EventAttribute(_, _, _) -> True
    _ -> False
  }
}

pub fn boolean_attr_test() {
  let attr = BooleanAttribute(name: "disabled")
  should.be_true(is_boolean_attr(attr))
  let BooleanAttribute(name) = attr
  should.equal(name, "disabled")
}

fn is_boolean_attr(attr: types.Attribute) -> Bool {
  case attr {
    BooleanAttribute(_) -> True
    _ -> False
  }
}

pub fn text_node_test() {
  let span = point_span(start_position())
  let node = TextNode(content: "Hello", span: span)
  should.be_true(is_text_node(node))
  let TextNode(content, _) = node
  should.equal(content, "Hello")
}

fn is_text_node(node: types.Node) -> Bool {
  case node {
    TextNode(_, _) -> True
    _ -> False
  }
}

pub fn expr_node_test() {
  let span = point_span(start_position())
  let node = ExprNode(expr: "user.name", span: span)
  should.be_true(is_expr_node(node))
  let ExprNode(expr, _) = node
  should.equal(expr, "user.name")
}

fn is_expr_node(node: types.Node) -> Bool {
  case node {
    ExprNode(_, _) -> True
    _ -> False
  }
}

pub fn element_node_test() {
  let span = point_span(start_position())
  let node =
    Element(
      tag: "div",
      attrs: [StaticAttribute("class", "box")],
      children: [TextNode("Hello", span)],
      span: span,
    )
  should.be_true(is_element_node(node))
  let Element(tag, attrs, children, _) = node
  should.equal(tag, "div")
  should.equal(list.length(attrs), 1)
  should.equal(list.length(children), 1)
}

fn is_element_node(node: types.Node) -> Bool {
  case node {
    Element(_, _, _, _) -> True
    _ -> False
  }
}

pub fn if_node_test() {
  let span = point_span(start_position())
  let node =
    IfNode(
      condition: "show",
      then_branch: [TextNode("Yes", span)],
      else_branch: [TextNode("No", span)],
      span: span,
    )
  should.be_true(is_if_node(node))
  let IfNode(condition, then_branch, else_branch, _) = node
  should.equal(condition, "show")
  should.equal(list.length(then_branch), 1)
  should.equal(list.length(else_branch), 1)
}

fn is_if_node(node: types.Node) -> Bool {
  case node {
    IfNode(_, _, _, _) -> True
    _ -> False
  }
}

pub fn each_node_test() {
  let span = point_span(start_position())
  let node =
    EachNode(
      collection: "items",
      item: "item",
      index: Some("i"),
      body: [TextNode("Item", span)],
      span: span,
    )
  should.be_true(is_each_node(node))
  let EachNode(collection, item, index, body, _) = node
  should.equal(collection, "items")
  should.equal(item, "item")
  should.equal(index, Some("i"))
  should.equal(list.length(body), 1)
}

fn is_each_node(node: types.Node) -> Bool {
  case node {
    EachNode(_, _, _, _, _) -> True
    _ -> False
  }
}

pub fn each_node_without_index_test() {
  let span = point_span(start_position())
  let node =
    EachNode(
      collection: "items",
      item: "item",
      index: None,
      body: [TextNode("Item", span)],
      span: span,
    )
  let EachNode(_, _, index, _, _) = node
  should.equal(index, None)
}

pub fn case_node_test() {
  let span = point_span(start_position())
  let branch =
    CaseBranch(pattern: "Ok(x)", body: [TextNode("Success", span)], span: span)
  let node = CaseNode(expr: "result", branches: [branch], span: span)
  should.be_true(is_case_node(node))
  let CaseNode(expr, branches, _) = node
  should.equal(expr, "result")
  should.equal(list.length(branches), 1)
}

fn is_case_node(node: types.Node) -> Bool {
  case node {
    CaseNode(_, _, _) -> True
    _ -> False
  }
}

pub fn fragment_node_test() {
  let span = point_span(start_position())
  let node =
    Fragment(children: [TextNode("A", span), TextNode("B", span)], span: span)
  should.be_true(is_fragment_node(node))
  let Fragment(children, _) = node
  should.equal(list.length(children), 2)
}

fn is_fragment_node(node: types.Node) -> Bool {
  case node {
    Fragment(_, _) -> True
    _ -> False
  }
}

pub fn template_test() {
  let span = point_span(start_position())
  let template =
    Template(
      imports: ["gleam/io", "gleam/list"],
      params: [#("name", "String"), #("count", "Int")],
      body: [TextNode("Hello", span)],
    )
  should.equal(list.length(template.imports), 2)
  should.equal(list.length(template.params), 2)
  should.equal(list.length(template.body), 1)
}

pub fn start_position_test() {
  let pos = start_position()
  should.equal(pos.line, 1)
  should.equal(pos.column, 1)
}

pub fn point_span_test() {
  let pos = Position(line: 5, column: 10)
  let span = point_span(pos)
  should.equal(span.start, pos)
  should.equal(span.end, pos)
}

pub fn target_lustre_test() {
  let target = Lustre
  should.be_true(is_lustre_target(target))
}

fn is_lustre_target(target: types.Target) -> Bool {
  case target {
    Lustre -> True
  }
}

// === Target Parsing Tests ===

pub fn target_from_string_lustre_test() {
  target_from_string("lustre")
  |> should.equal(Ok(Lustre))
}

pub fn target_from_string_invalid_test() {
  target_from_string("react")
  |> should.equal(Error(Nil))
}

pub fn target_from_string_empty_test() {
  target_from_string("")
  |> should.equal(Error(Nil))
}

pub fn valid_target_names_test() {
  valid_target_names()
  |> should.equal(["lustre"])
}

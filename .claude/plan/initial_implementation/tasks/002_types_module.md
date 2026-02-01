# Task 002: Types Module

## Description
Implement all type definitions in `types.gleam`. These types form the contract between parser and codegen, and are used throughout the application.

## Dependencies
- Task 001: Project Setup

## Success Criteria
1. All types from the plan are defined
2. Types compile without errors
3. Types can be imported and used from other modules
4. Unit tests verify type construction

## Implementation Steps

### 1. Define Position and Span types
```gleam
/// Position in source file for error reporting
pub type Position {
  Position(line: Int, column: Int)
}

/// Span of source text
pub type Span {
  Span(start: Position, end: Position)
}
```

### 2. Define ParseError and ParseResult
```gleam
/// Parse error with location information
pub type ParseError {
  ParseError(span: Span, message: String)
}

/// Result type for parsing operations
pub type ParseResult(a) =
  Result(a, List(ParseError))
```

### 3. Define Attr type
```gleam
pub type Attr {
  StaticAttr(name: String, value: String)
  DynamicAttr(name: String, expr: String)
  EventAttr(event: String, handler: String)
  BooleanAttr(name: String)
}
```

### 4. Define Token type
```gleam
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
  Comment(span: Span)
}
```

### 5. Define AST Node types
```gleam
/// AST Node representing parsed template structure
pub type Node {
  Element(tag: String, attrs: List(Attr), children: List(Node), span: Span)
  TextNode(content: String, span: Span)
  ExprNode(expr: String, span: Span)
  IfNode(
    condition: String,
    then_branch: List(Node),
    else_branch: List(Node),
    span: Span,
  )
  EachNode(
    collection: String,
    item: String,
    index: Option(String),
    body: List(Node),
    span: Span,
  )
  CaseNode(expr: String, branches: List(CaseBranch), span: Span)
  Fragment(children: List(Node), span: Span)
}

pub type CaseBranch {
  CaseBranch(pattern: String, body: List(Node), span: Span)
}
```

### 6. Define Template type
```gleam
/// Parsed template with metadata and body
pub type Template {
  Template(
    imports: List(String),
    params: List(#(String, String)),
    body: List(Node),
  )
}
```

### 7. Add helper constructors (optional but useful)
```gleam
/// Create a position at line 1, column 1
pub fn start_position() -> Position {
  Position(line: 1, column: 1)
}

/// Create a zero-length span at a position
pub fn point_span(pos: Position) -> Span {
  Span(start: pos, end: pos)
}
```

## Test Cases

### Test File: `test/types_test.gleam`

```gleam
import gleeunit/should
import lustre_template_gen/types.{
  Position, Span, ParseError, Attr, StaticAttr, DynamicAttr,
  EventAttr, BooleanAttr, Node, Element, TextNode, ExprNode,
  IfNode, EachNode, CaseNode, CaseBranch, Fragment, Template,
  start_position, point_span,
}
import gleam/option.{None, Some}

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
  let span = Span(
    start: Position(line: 5, column: 3),
    end: Position(line: 5, column: 10),
  )
  let error = ParseError(span: span, message: "Unexpected token")
  should.equal(error.message, "Unexpected token")
  should.equal(error.span.start.line, 5)
}

pub fn static_attr_test() {
  let attr = StaticAttr(name: "class", value: "container")
  case attr {
    StaticAttr(name, value) -> {
      should.equal(name, "class")
      should.equal(value, "container")
    }
    _ -> should.fail()
  }
}

pub fn dynamic_attr_test() {
  let attr = DynamicAttr(name: "class", expr: "my_class")
  case attr {
    DynamicAttr(name, expr) -> {
      should.equal(name, "class")
      should.equal(expr, "my_class")
    }
    _ -> should.fail()
  }
}

pub fn event_attr_test() {
  let attr = EventAttr(event: "click", handler: "handle_click()")
  case attr {
    EventAttr(event, handler) -> {
      should.equal(event, "click")
      should.equal(handler, "handle_click()")
    }
    _ -> should.fail()
  }
}

pub fn boolean_attr_test() {
  let attr = BooleanAttr(name: "disabled")
  case attr {
    BooleanAttr(name) -> should.equal(name, "disabled")
    _ -> should.fail()
  }
}

pub fn text_node_test() {
  let span = point_span(start_position())
  let node = TextNode(content: "Hello", span: span)
  case node {
    TextNode(content, _) -> should.equal(content, "Hello")
    _ -> should.fail()
  }
}

pub fn element_node_test() {
  let span = point_span(start_position())
  let node = Element(
    tag: "div",
    attrs: [StaticAttr("class", "box")],
    children: [TextNode("Hello", span)],
    span: span,
  )
  case node {
    Element(tag, attrs, children, _) -> {
      should.equal(tag, "div")
      should.equal(list.length(attrs), 1)
      should.equal(list.length(children), 1)
    }
    _ -> should.fail()
  }
}

pub fn if_node_test() {
  let span = point_span(start_position())
  let node = IfNode(
    condition: "show",
    then_branch: [TextNode("Yes", span)],
    else_branch: [TextNode("No", span)],
    span: span,
  )
  case node {
    IfNode(condition, then_branch, else_branch, _) -> {
      should.equal(condition, "show")
      should.equal(list.length(then_branch), 1)
      should.equal(list.length(else_branch), 1)
    }
    _ -> should.fail()
  }
}

pub fn each_node_test() {
  let span = point_span(start_position())
  let node = EachNode(
    collection: "items",
    item: "item",
    index: Some("i"),
    body: [TextNode("Item", span)],
    span: span,
  )
  case node {
    EachNode(collection, item, index, body, _) -> {
      should.equal(collection, "items")
      should.equal(item, "item")
      should.equal(index, Some("i"))
      should.equal(list.length(body), 1)
    }
    _ -> should.fail()
  }
}

pub fn case_node_test() {
  let span = point_span(start_position())
  let branch = CaseBranch(
    pattern: "Ok(x)",
    body: [TextNode("Success", span)],
    span: span,
  )
  let node = CaseNode(
    expr: "result",
    branches: [branch],
    span: span,
  )
  case node {
    CaseNode(expr, branches, _) -> {
      should.equal(expr, "result")
      should.equal(list.length(branches), 1)
    }
    _ -> should.fail()
  }
}

pub fn template_test() {
  let span = point_span(start_position())
  let template = Template(
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
```

## Verification Checklist
- [x] `gleam build` succeeds
- [x] `gleam test` passes all type tests
- [x] Types can be imported in other modules
- [x] All variants of each type are tested
- [x] Helper functions work correctly

## Notes
- Import `gleam/option.{type Option}` for the `Option` type in `EachNode`
- The `List` type is from the prelude, no import needed
- Consider adding `@external` doc comments for public types

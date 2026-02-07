//// Type definitions for the Lustre template parser and code generator.
////
//// This module defines all core types including source positions, tokens,
//// AST nodes, and the parsed template structure.

import gleam/option.{type Option}

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
pub type ParseResult(a) =
  Result(a, List(ParseError))

/// Attribute types for HTML elements
pub type Attr {
  StaticAttr(name: String, value: String)
  DynamicAttr(name: String, expr: String)
  EventAttr(event: String, handler: String, modifiers: List(String))
  BooleanAttr(name: String)
}

/// Token types produced by the tokenizer
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

/// A branch in a case expression
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

/// Create a position at line 1, column 1
pub fn start_position() -> Position {
  Position(line: 1, column: 1)
}

/// Create a zero-length span at a position
pub fn point_span(pos: Position) -> Span {
  Span(start: pos, end: pos)
}

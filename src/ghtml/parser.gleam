//// Template parser for `.ghtml` files.
////
//// Builds an AST from tokens produced by the lexer. The parser handles
//// stack-based nesting of HTML elements, control flow blocks, and metadata
//// extraction (imports/params).

import ghtml/lexer
import ghtml/types.{
  type Attribute, type CaseBranch, type Node, type ParseError, type ParseResult,
  type Span, type Template, type Token, CaseBranch, CaseEnd, CaseNode,
  CasePattern, CaseStart, EachEnd, EachNode, EachStart, Element, Else, Expr,
  ExprNode, HtmlClose, HtmlOpen, IfEnd, IfNode, IfStart, Import, Params,
  ParseError, Position, Span, Template, Text, TextNode,
}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

/// Stack frame for tracking nesting during AST construction
type StackFrame {
  ElementFrame(
    tag: String,
    attrs: List(Attribute),
    children: List(Node),
    span: Span,
  )
  IfFrame(
    condition: String,
    then_nodes: List(Node),
    else_nodes: List(Node),
    in_else: Bool,
    span: Span,
  )
  EachFrame(
    collection: String,
    item: String,
    index: Option(String),
    body: List(Node),
    span: Span,
  )
  CaseFrame(
    expr: String,
    current_pattern: Option(String),
    current_body: List(Node),
    branches: List(CaseBranch),
    span: Span,
  )
}

// === Main Parse Function ===

/// Parse a template string into a Template AST
pub fn parse(input: String) -> ParseResult(Template) {
  case lexer.tokenize(input) {
    Error(errors) -> Error(errors)
    Ok(tokens) -> {
      let #(imports, params, body_tokens) = extract_metadata(tokens)
      case build_ast(body_tokens) {
        Error(errors) -> Error(errors)
        Ok(body) -> Ok(Template(imports, params, body))
      }
    }
  }
}

// === Metadata Extraction ===

/// Extract imports and params from token list, returning remaining body tokens
fn extract_metadata(
  tokens: List(Token),
) -> #(List(String), List(#(String, String)), List(Token)) {
  extract_metadata_loop(tokens, [], [], [])
}

fn extract_metadata_loop(
  tokens: List(Token),
  imports: List(String),
  params: List(List(#(String, String))),
  body: List(Token),
) -> #(List(String), List(#(String, String)), List(Token)) {
  case tokens {
    [] -> #(
      list.reverse(imports),
      list.flatten(list.reverse(params)),
      list.reverse(body),
    )
    [Import(content: content, span: _), ..rest] ->
      extract_metadata_loop(rest, [content, ..imports], params, body)
    [Params(params: p, span: _), ..rest] ->
      extract_metadata_loop(rest, imports, [p, ..params], body)
    [token, ..rest] ->
      extract_metadata_loop(rest, imports, params, [token, ..body])
  }
}

// === AST Builder ===

/// Build an AST from a list of tokens.
/// Uses a stack to track nesting. Each frame on the stack has its own children list.
/// When we close a frame, we create a node with its accumulated children and add it
/// to the parent frame's children (or to the result if no parent).
pub fn build_ast(tokens: List(Token)) -> Result(List(Node), List(ParseError)) {
  build_ast_loop(tokens, [], [])
}

fn build_ast_loop(
  tokens: List(Token),
  stack: List(StackFrame),
  errors: List(ParseError),
) -> Result(List(Node), List(ParseError)) {
  case tokens {
    [] -> {
      // Check for unclosed structures and extract result
      case stack, errors {
        [], [] -> Ok([])
        [], _ -> Error(list.reverse(errors))
        // Virtual root frame (tag="") contains our top-level nodes
        [ElementFrame(tag: "", attrs: _, children: children, span: _)], [] ->
          Ok(list.reverse(children))
        [ElementFrame(tag: "", attrs: _, children: _, span: _)], _ ->
          Error(list.reverse(errors))
        // Any other frame is an unclosed structure
        [frame, ..], _ -> {
          let error = unclosed_frame_error(frame)
          Error(list.reverse([error, ..errors]))
        }
      }
    }

    [token, ..rest] -> {
      case token {
        // HTML opening tag - self-closing
        HtmlOpen(tag: tag, attrs: attrs, self_closing: True, span: span) -> {
          let node = Element(tag: tag, attrs: attrs, children: [], span: span)
          let stack = add_node_to_stack(node, stack)
          build_ast_loop(rest, stack, errors)
        }

        // HTML opening tag - push new frame
        HtmlOpen(tag: tag, attrs: attrs, self_closing: False, span: span) -> {
          let frame =
            ElementFrame(tag: tag, attrs: attrs, children: [], span: span)
          build_ast_loop(rest, [frame, ..stack], errors)
        }

        // HTML closing tag
        HtmlClose(tag: close_tag, span: close_span) -> {
          case stack {
            [
              ElementFrame(
                tag: open_tag,
                attrs: attrs,
                children: children,
                span: span,
              ),
              ..rest_stack
            ] -> {
              case open_tag == close_tag {
                True -> {
                  let combined_span =
                    Span(start: span.start, end: close_span.end)
                  let node =
                    Element(
                      tag: open_tag,
                      attrs: attrs,
                      children: list.reverse(children),
                      span: combined_span,
                    )
                  let new_stack = add_node_to_stack(node, rest_stack)
                  build_ast_loop(rest, new_stack, errors)
                }
                False -> {
                  let error =
                    ParseError(
                      close_span,
                      "Mismatched closing tag: expected </"
                        <> open_tag
                        <> "> but found </"
                        <> close_tag
                        <> ">",
                    )
                  build_ast_loop(rest, stack, [error, ..errors])
                }
              }
            }
            _ -> {
              let error =
                ParseError(
                  close_span,
                  "Unexpected closing tag </" <> close_tag <> ">",
                )
              build_ast_loop(rest, stack, [error, ..errors])
            }
          }
        }

        // Text content
        Text(content: content, span: span) -> {
          let node = TextNode(content: content, span: span)
          let stack = add_node_to_stack(node, stack)
          build_ast_loop(rest, stack, errors)
        }

        // Expression
        Expr(content: content, span: span) -> {
          let node = ExprNode(expr: content, span: span)
          let stack = add_node_to_stack(node, stack)
          build_ast_loop(rest, stack, errors)
        }

        // If start
        IfStart(condition: condition, span: span) -> {
          let frame =
            IfFrame(
              condition: condition,
              then_nodes: [],
              else_nodes: [],
              in_else: False,
              span: span,
            )
          build_ast_loop(rest, [frame, ..stack], errors)
        }

        // Else - switch to else branch
        Else(span: else_span) -> {
          case stack {
            [
              IfFrame(
                condition: cond,
                then_nodes: then_nodes,
                else_nodes: _,
                in_else: False,
                span: span,
              ),
              ..rest_stack
            ] -> {
              let new_frame =
                IfFrame(
                  condition: cond,
                  then_nodes: list.reverse(then_nodes),
                  else_nodes: [],
                  in_else: True,
                  span: span,
                )
              build_ast_loop(rest, [new_frame, ..rest_stack], errors)
            }
            _ -> {
              let error =
                ParseError(else_span, "{:else} without matching {#if}")
              build_ast_loop(rest, stack, [error, ..errors])
            }
          }
        }

        // If end
        IfEnd(span: end_span) -> {
          case stack {
            [
              IfFrame(
                condition: cond,
                then_nodes: then_nodes,
                else_nodes: else_nodes,
                in_else: in_else,
                span: span,
              ),
              ..rest_stack
            ] -> {
              let #(final_then, final_else) = case in_else {
                True -> #(then_nodes, list.reverse(else_nodes))
                False -> #(list.reverse(then_nodes), [])
              }
              let combined_span = Span(start: span.start, end: end_span.end)
              let node =
                IfNode(
                  condition: cond,
                  then_branch: final_then,
                  else_branch: final_else,
                  span: combined_span,
                )
              let new_stack = add_node_to_stack(node, rest_stack)
              build_ast_loop(rest, new_stack, errors)
            }
            _ -> {
              let error = ParseError(end_span, "{/if} without matching {#if}")
              build_ast_loop(rest, stack, [error, ..errors])
            }
          }
        }

        // Each start
        EachStart(collection: collection, item: item, index: index, span: span) -> {
          let frame =
            EachFrame(
              collection: collection,
              item: item,
              index: index,
              body: [],
              span: span,
            )
          build_ast_loop(rest, [frame, ..stack], errors)
        }

        // Each end
        EachEnd(span: end_span) -> {
          case stack {
            [
              EachFrame(
                collection: coll,
                item: item,
                index: index,
                body: body,
                span: span,
              ),
              ..rest_stack
            ] -> {
              let combined_span = Span(start: span.start, end: end_span.end)
              let node =
                EachNode(
                  collection: coll,
                  item: item,
                  index: index,
                  body: list.reverse(body),
                  span: combined_span,
                )
              let new_stack = add_node_to_stack(node, rest_stack)
              build_ast_loop(rest, new_stack, errors)
            }
            _ -> {
              let error =
                ParseError(end_span, "{/each} without matching {#each}")
              build_ast_loop(rest, stack, [error, ..errors])
            }
          }
        }

        // Case start
        CaseStart(expr: expr, span: span) -> {
          let frame =
            CaseFrame(
              expr: expr,
              current_pattern: None,
              current_body: [],
              branches: [],
              span: span,
            )
          build_ast_loop(rest, [frame, ..stack], errors)
        }

        // Case pattern
        CasePattern(pattern: pattern, span: pattern_span) -> {
          case stack {
            [
              CaseFrame(
                expr: expr,
                current_pattern: curr_pat,
                current_body: body,
                branches: branches,
                span: span,
              ),
              ..rest_stack
            ] -> {
              // Finalize previous branch if there was one
              let new_branches = case curr_pat {
                Some(prev_pattern) -> {
                  let branch =
                    CaseBranch(
                      pattern: prev_pattern,
                      body: list.reverse(body),
                      span: pattern_span,
                    )
                  [branch, ..branches]
                }
                None -> branches
              }
              let new_frame =
                CaseFrame(
                  expr: expr,
                  current_pattern: Some(pattern),
                  current_body: [],
                  branches: new_branches,
                  span: span,
                )
              build_ast_loop(rest, [new_frame, ..rest_stack], errors)
            }
            _ -> {
              let error =
                ParseError(pattern_span, "Case pattern outside of {#case}")
              build_ast_loop(rest, stack, [error, ..errors])
            }
          }
        }

        // Case end
        CaseEnd(span: end_span) -> {
          case stack {
            [
              CaseFrame(
                expr: expr,
                current_pattern: curr_pat,
                current_body: body,
                branches: branches,
                span: span,
              ),
              ..rest_stack
            ] -> {
              // Finalize the last branch
              let final_branches = case curr_pat {
                Some(pattern) -> {
                  let branch =
                    CaseBranch(
                      pattern: pattern,
                      body: list.reverse(body),
                      span: end_span,
                    )
                  list.reverse([branch, ..branches])
                }
                None -> list.reverse(branches)
              }
              let combined_span = Span(start: span.start, end: end_span.end)
              let node =
                CaseNode(
                  expr: expr,
                  branches: final_branches,
                  span: combined_span,
                )
              let new_stack = add_node_to_stack(node, rest_stack)
              build_ast_loop(rest, new_stack, errors)
            }
            _ -> {
              let error =
                ParseError(end_span, "{/case} without matching {#case}")
              build_ast_loop(rest, stack, [error, ..errors])
            }
          }
        }

        // Comment (skip)
        types.Comment(span: _) -> {
          build_ast_loop(rest, stack, errors)
        }

        // Import and Params should have been extracted already
        Import(content: _, span: _) -> {
          build_ast_loop(rest, stack, errors)
        }

        Params(params: _, span: _) -> {
          build_ast_loop(rest, stack, errors)
        }
      }
    }
  }
}

/// Add a node to the top frame's children, or create a root frame if stack is empty
fn add_node_to_stack(node: Node, stack: List(StackFrame)) -> List(StackFrame) {
  case stack {
    [] -> {
      // Create a virtual root frame to hold top-level nodes
      [
        ElementFrame(
          tag: "",
          attrs: [],
          children: [node],
          span: Span(start: Position(1, 1), end: Position(1, 1)),
        ),
      ]
    }
    [frame, ..rest] -> {
      let new_children = get_frame_children(frame)
      let updated_frame = set_frame_children(frame, [node, ..new_children])
      [updated_frame, ..rest]
    }
  }
}

/// Get children list from a frame
fn get_frame_children(frame: StackFrame) -> List(Node) {
  case frame {
    ElementFrame(tag: _, attrs: _, children: children, span: _) -> children
    IfFrame(
      condition: _,
      then_nodes: nodes,
      else_nodes: _,
      in_else: False,
      span: _,
    ) -> nodes
    IfFrame(
      condition: _,
      then_nodes: _,
      else_nodes: nodes,
      in_else: True,
      span: _,
    ) -> nodes
    EachFrame(collection: _, item: _, index: _, body: body, span: _) -> body
    CaseFrame(
      expr: _,
      current_pattern: _,
      current_body: body,
      branches: _,
      span: _,
    ) -> body
  }
}

/// Set children list on a frame
fn set_frame_children(frame: StackFrame, children: List(Node)) -> StackFrame {
  case frame {
    ElementFrame(tag: tag, attrs: attrs, children: _, span: span) ->
      ElementFrame(tag: tag, attrs: attrs, children: children, span: span)
    IfFrame(
      condition: cond,
      then_nodes: _,
      else_nodes: else_n,
      in_else: False,
      span: span,
    ) ->
      IfFrame(
        condition: cond,
        then_nodes: children,
        else_nodes: else_n,
        in_else: False,
        span: span,
      )
    IfFrame(
      condition: cond,
      then_nodes: then_n,
      else_nodes: _,
      in_else: True,
      span: span,
    ) ->
      IfFrame(
        condition: cond,
        then_nodes: then_n,
        else_nodes: children,
        in_else: True,
        span: span,
      )
    EachFrame(collection: coll, item: item, index: idx, body: _, span: span) ->
      EachFrame(
        collection: coll,
        item: item,
        index: idx,
        body: children,
        span: span,
      )
    CaseFrame(
      expr: expr,
      current_pattern: pat,
      current_body: _,
      branches: br,
      span: span,
    ) ->
      CaseFrame(
        expr: expr,
        current_pattern: pat,
        current_body: children,
        branches: br,
        span: span,
      )
  }
}

/// Create an error for an unclosed frame
fn unclosed_frame_error(frame: StackFrame) -> ParseError {
  case frame {
    ElementFrame(tag: tag, attrs: _, children: _, span: span) ->
      ParseError(span, "Unclosed element <" <> tag <> ">")
    IfFrame(condition: _, then_nodes: _, else_nodes: _, in_else: _, span: span) ->
      ParseError(span, "Unclosed {#if} block")
    EachFrame(collection: _, item: _, index: _, body: _, span: span) ->
      ParseError(span, "Unclosed {#each} block")
    CaseFrame(
      expr: _,
      current_pattern: _,
      current_body: _,
      branches: _,
      span: span,
    ) -> ParseError(span, "Unclosed {#case} block")
  }
}

// === Error Formatting ===

/// Format a single parse error with source context
pub fn format_error(error: ParseError, source: String) -> String {
  let ParseError(span: span, message: message) = error
  let lines = string.split(source, "\n")
  let line_num = span.start.line
  let line_content =
    lines
    |> list.drop(line_num - 1)
    |> list.first()
    |> result.unwrap("")

  let line_prefix = int.to_string(line_num) <> " | "
  let pointer_offset =
    string.repeat(" ", string.length(line_prefix) + span.start.column - 1)
  let pointer = pointer_offset <> "^"

  "Error at line "
  <> int.to_string(line_num)
  <> ", column "
  <> int.to_string(span.start.column)
  <> ": "
  <> message
  <> "\n"
  <> line_prefix
  <> line_content
  <> "\n"
  <> pointer
}

/// Format multiple parse errors
pub fn format_errors(errors: List(ParseError), source: String) -> String {
  errors
  |> list.map(fn(err) { format_error(err, source) })
  |> string.join("\n\n")
}

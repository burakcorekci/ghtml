//// Template parser for `.ghtml` files.
////
//// Converts template source text into tokens and builds an AST representing
//// the template structure including HTML elements, expressions, and control flow.

import ghtml/types.{
  type Attr, type CaseBranch, type Node, type ParseError, type ParseResult,
  type Position, type Span, type Template, type Token, BooleanAttr, CaseBranch,
  CaseEnd, CaseNode, CasePattern, CaseStart, DynamicAttr, EachEnd, EachNode,
  EachStart, Element, Else, EventAttr, Expr, ExprNode, HtmlClose, HtmlOpen,
  IfEnd, IfNode, IfStart, Import, Params, ParseError, Position, Span, StaticAttr,
  Template, Text, TextNode,
}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

/// Stack frame for tracking nesting during AST construction
type StackFrame {
  ElementFrame(tag: String, attrs: List(Attr), children: List(Node), span: Span)
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

/// Tokenize a template string into a list of tokens
pub fn tokenize(input: String) -> Result(List(Token), List(ParseError)) {
  let pos = Position(line: 1, column: 1)
  tokenize_loop(input, pos, [])
  |> result.map(fn(tokens) { list.reverse(tokens) })
}

fn tokenize_loop(
  input: String,
  pos: Position,
  tokens: List(Token),
) -> Result(List(Token), List(ParseError)) {
  case input {
    "" -> Ok(tokens)

    // Directive: @import or @params
    "@import" <> rest -> {
      let start_pos = pos
      let pos = advance_pos_str(pos, "@import")
      case parse_import(rest, start_pos, pos) {
        Ok(#(token, remaining, new_pos)) ->
          tokenize_loop(remaining, new_pos, [token, ..tokens])
        Error(err) -> Error([err])
      }
    }

    "@params" <> rest -> {
      let start_pos = pos
      let pos = advance_pos_str(pos, "@params")
      case parse_params(rest, start_pos, pos) {
        Ok(#(token, remaining, new_pos)) ->
          tokenize_loop(remaining, new_pos, [token, ..tokens])
        Error(err) -> Error([err])
      }
    }

    // HTML comment: <!-- ... -->
    "<!--" <> rest -> {
      let pos = advance_pos_str(pos, "<!--")
      case skip_html_comment(rest, pos) {
        Ok(#(remaining, new_pos)) -> tokenize_loop(remaining, new_pos, tokens)
        Error(err) -> Error([err])
      }
    }

    // HTML closing tag: </tag>
    "</" <> rest -> {
      let start_pos = pos
      let pos = advance_pos_str(pos, "</")
      case parse_close_tag(rest, start_pos, pos) {
        Ok(#(token, remaining, new_pos)) ->
          tokenize_loop(remaining, new_pos, [token, ..tokens])
        Error(err) -> Error([err])
      }
    }

    // HTML opening tag: <tag ...>
    "<" <> rest -> {
      let start_pos = pos
      let pos = advance_pos(pos, "<")
      case parse_open_tag(rest, start_pos, pos) {
        Ok(#(token, remaining, new_pos)) ->
          tokenize_loop(remaining, new_pos, [token, ..tokens])
        Error(err) -> Error([err])
      }
    }

    // Control flow or expression: {#if}, {:else}, {/if}, {expr}
    "{" <> rest -> {
      let start_pos = pos
      let pos = advance_pos(pos, "{")
      case parse_brace_content(rest, start_pos, pos) {
        Ok(#(token, remaining, new_pos)) ->
          tokenize_loop(remaining, new_pos, [token, ..tokens])
        Error(err) -> Error([err])
      }
    }

    // Text content
    _ -> {
      let start_pos = pos
      let #(text, remaining, new_pos) = parse_text(input, "", pos)
      case text {
        "" -> {
          // No text was parsed, we're stuck - shouldn't happen but be safe
          case string.pop_grapheme(input) {
            Ok(#(_, rest)) -> tokenize_loop(rest, advance_pos(pos, "_"), tokens)
            Error(_) -> Ok(tokens)
          }
        }
        _ -> {
          // Skip whitespace-only text tokens
          case is_whitespace_only(text) {
            True -> tokenize_loop(remaining, new_pos, tokens)
            False -> {
              let span = Span(start: start_pos, end: new_pos)
              let token = Text(content: text, span: span)
              tokenize_loop(remaining, new_pos, [token, ..tokens])
            }
          }
        }
      }
    }
  }
}

// === Position Tracking ===

fn advance_pos(pos: Position, char: String) -> Position {
  case char {
    "\n" -> Position(line: pos.line + 1, column: 1)
    _ -> Position(line: pos.line, column: pos.column + 1)
  }
}

fn advance_pos_str(pos: Position, str: String) -> Position {
  string.to_graphemes(str)
  |> list.fold(pos, advance_pos)
}

// === Import Parsing ===

fn parse_import(
  input: String,
  start_pos: Position,
  pos: Position,
) -> Result(#(Token, String, Position), ParseError) {
  case input {
    "(" <> rest -> {
      let pos = advance_pos(pos, "(")
      case extract_balanced_parens(rest, 0, "", pos) {
        Ok(#(content, remaining, end_pos)) -> {
          let span = Span(start: start_pos, end: end_pos)
          Ok(#(Import(content: content, span: span), remaining, end_pos))
        }
        Error(err) -> Error(err)
      }
    }
    _ ->
      Error(ParseError(Span(start: pos, end: pos), "Expected '(' after @import"))
  }
}

// === Params Parsing ===

fn parse_params(
  input: String,
  start_pos: Position,
  pos: Position,
) -> Result(#(Token, String, Position), ParseError) {
  case input {
    "(" <> rest -> {
      let pos = advance_pos(pos, "(")
      case extract_balanced_parens(rest, 0, "", pos) {
        Ok(#(content, remaining, end_pos)) -> {
          let params = parse_param_list(content)
          let span = Span(start: start_pos, end: end_pos)
          Ok(#(Params(params: params, span: span), remaining, end_pos))
        }
        Error(err) -> Error(err)
      }
    }
    _ ->
      Error(ParseError(Span(start: pos, end: pos), "Expected '(' after @params"))
  }
}

fn parse_param_list(content: String) -> List(#(String, String)) {
  content
  |> string.trim()
  |> split_params([], "", 0)
  |> list.filter_map(fn(param_str) {
    let param_str = string.trim(param_str)
    case param_str {
      "" -> Error(Nil)
      _ -> {
        case string.split_once(param_str, ":") {
          Ok(#(name, type_str)) ->
            Ok(#(string.trim(name), string.trim(type_str)))
          Error(_) -> Error(Nil)
        }
      }
    }
  })
}

fn split_params(
  input: String,
  acc: List(String),
  current: String,
  depth: Int,
) -> List(String) {
  case string.pop_grapheme(input) {
    Error(_) -> {
      case current {
        "" -> list.reverse(acc)
        _ -> list.reverse([current, ..acc])
      }
    }
    Ok(#(char, rest)) -> {
      case char {
        "(" | "[" | "{" -> split_params(rest, acc, current <> char, depth + 1)
        ")" | "]" | "}" -> split_params(rest, acc, current <> char, depth - 1)
        "," if depth == 0 -> split_params(rest, [current, ..acc], "", 0)
        _ -> split_params(rest, acc, current <> char, depth)
      }
    }
  }
}

// === HTML Tag Parsing ===

fn parse_close_tag(
  input: String,
  start_pos: Position,
  pos: Position,
) -> Result(#(Token, String, Position), ParseError) {
  let #(tag_name, rest, new_pos) = extract_tag_name(input, "", pos)
  case tag_name {
    "" -> Error(ParseError(Span(start: pos, end: pos), "Expected tag name"))
    _ -> {
      // Skip whitespace and find closing >
      let #(rest, new_pos) = skip_whitespace(rest, new_pos)
      case rest {
        ">" <> remaining -> {
          let end_pos = advance_pos(new_pos, ">")
          let span = Span(start: start_pos, end: end_pos)
          Ok(#(HtmlClose(tag: tag_name, span: span), remaining, end_pos))
        }
        _ ->
          Error(ParseError(
            Span(start: new_pos, end: new_pos),
            "Expected '>' in closing tag",
          ))
      }
    }
  }
}

fn parse_open_tag(
  input: String,
  start_pos: Position,
  pos: Position,
) -> Result(#(Token, String, Position), ParseError) {
  let #(tag_name, rest, new_pos) = extract_tag_name(input, "", pos)
  case tag_name {
    "" -> Error(ParseError(Span(start: pos, end: pos), "Expected tag name"))
    _ -> {
      // Parse attributes
      case parse_attributes(rest, new_pos, []) {
        Ok(#(attrs, remaining, attr_end_pos)) -> {
          // Check for self-closing or regular closing
          let #(remaining, attr_end_pos) =
            skip_whitespace(remaining, attr_end_pos)
          case remaining {
            "/>" <> after -> {
              let end_pos = advance_pos_str(attr_end_pos, "/>")
              let span = Span(start: start_pos, end: end_pos)
              Ok(#(
                HtmlOpen(
                  tag: tag_name,
                  attrs: list.reverse(attrs),
                  self_closing: True,
                  span: span,
                ),
                after,
                end_pos,
              ))
            }
            ">" <> after -> {
              let end_pos = advance_pos(attr_end_pos, ">")
              let span = Span(start: start_pos, end: end_pos)
              Ok(#(
                HtmlOpen(
                  tag: tag_name,
                  attrs: list.reverse(attrs),
                  self_closing: False,
                  span: span,
                ),
                after,
                end_pos,
              ))
            }
            _ ->
              Error(ParseError(
                Span(start: attr_end_pos, end: attr_end_pos),
                "Expected '>' or '/>' to close tag",
              ))
          }
        }
        Error(err) -> Error(err)
      }
    }
  }
}

fn extract_tag_name(
  input: String,
  acc: String,
  pos: Position,
) -> #(String, String, Position) {
  case string.pop_grapheme(input) {
    Error(_) -> #(acc, input, pos)
    Ok(#(char, rest)) -> {
      case is_tag_name_char(char) {
        True -> extract_tag_name(rest, acc <> char, advance_pos(pos, char))
        False -> #(acc, input, pos)
      }
    }
  }
}

fn is_tag_name_char(char: String) -> Bool {
  case char {
    "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z"
    | "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z"
    | "0"
    | "1"
    | "2"
    | "3"
    | "4"
    | "5"
    | "6"
    | "7"
    | "8"
    | "9"
    | "-"
    | "_" -> True
    _ -> False
  }
}

// === Attribute Parsing ===

fn parse_attributes(
  input: String,
  pos: Position,
  attrs: List(Attr),
) -> Result(#(List(Attr), String, Position), ParseError) {
  let #(input, pos) = skip_whitespace(input, pos)

  // Check if we've reached the end of attributes
  case input {
    ">" <> _ | "/>" <> _ | "" -> Ok(#(attrs, input, pos))
    _ -> {
      // Try to parse an attribute
      case parse_single_attribute(input, pos) {
        Ok(#(attr, remaining, new_pos)) ->
          parse_attributes(remaining, new_pos, [attr, ..attrs])
        Error(err) -> Error(err)
      }
    }
  }
}

fn parse_single_attribute(
  input: String,
  pos: Position,
) -> Result(#(Attr, String, Position), ParseError) {
  case input {
    // Event attribute: @event={handler} or @event.prevent.stop={handler}
    "@" <> rest -> {
      let pos = advance_pos(pos, "@")
      let #(event_name, rest, new_pos) = extract_attr_name(rest, "", pos)
      // Parse optional .prevent and .stop modifiers
      case parse_event_modifiers(rest, new_pos, False, False) {
        Ok(#(prevent_default, stop_propagation, rest, new_pos)) -> {
          case rest {
            "={" <> after -> {
              let new_pos = advance_pos_str(new_pos, "={")
              case extract_expression(after, 0, "", new_pos) {
                Ok(#(handler, remaining, end_pos)) ->
                  Ok(#(
                    EventAttr(
                      event: event_name,
                      handler: handler,
                      prevent_default: prevent_default,
                      stop_propagation: stop_propagation,
                    ),
                    remaining,
                    end_pos,
                  ))
                Error(err) -> Error(err)
              }
            }
            _ ->
              Error(ParseError(
                Span(start: new_pos, end: new_pos),
                "Expected '={' after event attribute name",
              ))
          }
        }
        Error(err) -> Error(err)
      }
    }

    // Regular attribute
    _ -> {
      let #(attr_name, rest, new_pos) = extract_attr_name(input, "", pos)
      case attr_name {
        "" ->
          Error(ParseError(
            Span(start: pos, end: pos),
            "Expected attribute name",
          ))
        _ -> {
          case rest {
            // Dynamic attribute: name={expr}
            "={" <> after -> {
              let new_pos = advance_pos_str(new_pos, "={")
              case extract_expression(after, 0, "", new_pos) {
                Ok(#(expr, remaining, end_pos)) ->
                  Ok(#(
                    DynamicAttr(name: attr_name, expr: expr),
                    remaining,
                    end_pos,
                  ))
                Error(err) -> Error(err)
              }
            }

            // Static attribute: name="value"
            "=\"" <> after -> {
              let new_pos = advance_pos_str(new_pos, "=\"")
              case extract_quoted_value(after, "", new_pos) {
                Ok(#(value, remaining, end_pos)) ->
                  Ok(#(
                    StaticAttr(name: attr_name, value: value),
                    remaining,
                    end_pos,
                  ))
                Error(err) -> Error(err)
              }
            }

            // Static attribute with single quotes: name='value'
            "='" <> after -> {
              let new_pos = advance_pos_str(new_pos, "='")
              case extract_single_quoted_value(after, "", new_pos) {
                Ok(#(value, remaining, end_pos)) ->
                  Ok(#(
                    StaticAttr(name: attr_name, value: value),
                    remaining,
                    end_pos,
                  ))
                Error(err) -> Error(err)
              }
            }

            // Boolean attribute (no value)
            _ -> Ok(#(BooleanAttr(name: attr_name), rest, new_pos))
          }
        }
      }
    }
  }
}

fn extract_attr_name(
  input: String,
  acc: String,
  pos: Position,
) -> #(String, String, Position) {
  case string.pop_grapheme(input) {
    Error(_) -> #(acc, input, pos)
    Ok(#(char, rest)) -> {
      case is_attr_name_char(char) {
        True -> extract_attr_name(rest, acc <> char, advance_pos(pos, char))
        False -> #(acc, input, pos)
      }
    }
  }
}

fn is_attr_name_char(char: String) -> Bool {
  case char {
    "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z"
    | "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z"
    | "0"
    | "1"
    | "2"
    | "3"
    | "4"
    | "5"
    | "6"
    | "7"
    | "8"
    | "9"
    | "-"
    | "_"
    | ":" -> True
    _ -> False
  }
}

/// Parse event modifiers like .prevent and .stop after event name
fn parse_event_modifiers(
  input: String,
  pos: Position,
  prevent_default: Bool,
  stop_propagation: Bool,
) -> Result(#(Bool, Bool, String, Position), ParseError) {
  case input {
    ".prevent" <> rest -> {
      let new_pos = advance_pos_str(pos, ".prevent")
      parse_event_modifiers(rest, new_pos, True, stop_propagation)
    }
    ".stop" <> rest -> {
      let new_pos = advance_pos_str(pos, ".stop")
      parse_event_modifiers(rest, new_pos, prevent_default, True)
    }
    "." <> _ -> {
      Error(ParseError(
        Span(start: pos, end: pos),
        "Unknown event modifier (expected 'prevent' or 'stop')",
      ))
    }
    _ -> Ok(#(prevent_default, stop_propagation, input, pos))
  }
}

fn extract_quoted_value(
  input: String,
  acc: String,
  pos: Position,
) -> Result(#(String, String, Position), ParseError) {
  case string.pop_grapheme(input) {
    Error(_) ->
      Error(ParseError(Span(start: pos, end: pos), "Unterminated string"))
    Ok(#("\"", rest)) -> {
      let end_pos = advance_pos(pos, "\"")
      Ok(#(acc, rest, end_pos))
    }
    Ok(#("\\", rest)) -> {
      case string.pop_grapheme(rest) {
        Ok(#(escaped, rest2)) -> {
          let new_pos = advance_pos(advance_pos(pos, "\\"), escaped)
          extract_quoted_value(rest2, acc <> escaped, new_pos)
        }
        Error(_) ->
          Error(ParseError(Span(start: pos, end: pos), "Unterminated escape"))
      }
    }
    Ok(#(char, rest)) ->
      extract_quoted_value(rest, acc <> char, advance_pos(pos, char))
  }
}

fn extract_single_quoted_value(
  input: String,
  acc: String,
  pos: Position,
) -> Result(#(String, String, Position), ParseError) {
  case string.pop_grapheme(input) {
    Error(_) ->
      Error(ParseError(Span(start: pos, end: pos), "Unterminated string"))
    Ok(#("'", rest)) -> {
      let end_pos = advance_pos(pos, "'")
      Ok(#(acc, rest, end_pos))
    }
    Ok(#("\\", rest)) -> {
      case string.pop_grapheme(rest) {
        Ok(#(escaped, rest2)) -> {
          let new_pos = advance_pos(advance_pos(pos, "\\"), escaped)
          extract_single_quoted_value(rest2, acc <> escaped, new_pos)
        }
        Error(_) ->
          Error(ParseError(Span(start: pos, end: pos), "Unterminated escape"))
      }
    }
    Ok(#(char, rest)) ->
      extract_single_quoted_value(rest, acc <> char, advance_pos(pos, char))
  }
}

// === Brace Content Parsing (Expressions and Control Flow) ===

fn parse_brace_content(
  input: String,
  start_pos: Position,
  pos: Position,
) -> Result(#(Token, String, Position), ParseError) {
  case input {
    // Control flow: {#if condition}
    "#if " <> rest -> {
      let pos = advance_pos_str(pos, "#if ")
      case extract_expression(rest, 0, "", pos) {
        Ok(#(condition, remaining, end_pos)) -> {
          let span = Span(start: start_pos, end: end_pos)
          Ok(#(
            IfStart(condition: string.trim(condition), span: span),
            remaining,
            end_pos,
          ))
        }
        Error(err) -> Error(err)
      }
    }

    // Else: {:else}
    ":else}" <> rest -> {
      let end_pos = advance_pos_str(pos, ":else}")
      let span = Span(start: start_pos, end: end_pos)
      Ok(#(Else(span: span), rest, end_pos))
    }

    // End if: {/if}
    "/if}" <> rest -> {
      let end_pos = advance_pos_str(pos, "/if}")
      let span = Span(start: start_pos, end: end_pos)
      Ok(#(IfEnd(span: span), rest, end_pos))
    }

    // Each: {#each collection as item} or {#each collection as item, index}
    "#each " <> rest -> {
      let pos = advance_pos_str(pos, "#each ")
      case parse_each_header(rest, pos) {
        Ok(#(collection, item, index, remaining, end_pos)) -> {
          let span = Span(start: start_pos, end: end_pos)
          Ok(#(
            EachStart(
              collection: collection,
              item: item,
              index: index,
              span: span,
            ),
            remaining,
            end_pos,
          ))
        }
        Error(err) -> Error(err)
      }
    }

    // End each: {/each}
    "/each}" <> rest -> {
      let end_pos = advance_pos_str(pos, "/each}")
      let span = Span(start: start_pos, end: end_pos)
      Ok(#(EachEnd(span: span), rest, end_pos))
    }

    // Case: {#case expr}
    "#case " <> rest -> {
      let pos = advance_pos_str(pos, "#case ")
      case extract_expression(rest, 0, "", pos) {
        Ok(#(expr, remaining, end_pos)) -> {
          let span = Span(start: start_pos, end: end_pos)
          Ok(#(
            CaseStart(expr: string.trim(expr), span: span),
            remaining,
            end_pos,
          ))
        }
        Error(err) -> Error(err)
      }
    }

    // Case pattern: {:Pattern} or {:Pattern(x)}
    ":" <> rest -> {
      let pos = advance_pos(pos, ":")
      case extract_pattern(rest, "", pos) {
        Ok(#(pattern, remaining, end_pos)) -> {
          let span = Span(start: start_pos, end: end_pos)
          Ok(#(CasePattern(pattern: pattern, span: span), remaining, end_pos))
        }
        Error(err) -> Error(err)
      }
    }

    // End case: {/case}
    "/case}" <> rest -> {
      let end_pos = advance_pos_str(pos, "/case}")
      let span = Span(start: start_pos, end: end_pos)
      Ok(#(CaseEnd(span: span), rest, end_pos))
    }

    // Regular expression: {expr}
    _ -> {
      case extract_expression(input, 0, "", pos) {
        Ok(#(expr, remaining, end_pos)) -> {
          let span = Span(start: start_pos, end: end_pos)
          Ok(#(Expr(content: expr, span: span), remaining, end_pos))
        }
        Error(err) -> Error(err)
      }
    }
  }
}

fn parse_each_header(
  input: String,
  pos: Position,
) -> Result(#(String, String, Option(String), String, Position), ParseError) {
  // Find " as " to split collection from binding
  case find_as_keyword(input, "", pos) {
    Ok(#(collection, rest, new_pos)) -> {
      // Parse item and optional index until closing brace
      let #(binding, rest, end_pos) =
        extract_until_close_brace(rest, "", new_pos)
      let #(item, index) = parse_binding(binding)
      Ok(#(string.trim(collection), item, index, rest, end_pos))
    }
    Error(err) -> Error(err)
  }
}

fn find_as_keyword(
  input: String,
  acc: String,
  pos: Position,
) -> Result(#(String, String, Position), ParseError) {
  case input {
    "" ->
      Error(ParseError(
        Span(start: pos, end: pos),
        "Expected 'as' keyword in each",
      ))
    " as " <> rest -> {
      let new_pos = advance_pos_str(pos, " as ")
      Ok(#(acc, rest, new_pos))
    }
    _ -> {
      case string.pop_grapheme(input) {
        Ok(#(char, rest)) ->
          find_as_keyword(rest, acc <> char, advance_pos(pos, char))
        Error(_) ->
          Error(ParseError(
            Span(start: pos, end: pos),
            "Expected 'as' keyword in each",
          ))
      }
    }
  }
}

fn extract_until_close_brace(
  input: String,
  acc: String,
  pos: Position,
) -> #(String, String, Position) {
  case string.pop_grapheme(input) {
    Error(_) -> #(acc, input, pos)
    Ok(#("}", rest)) -> {
      let end_pos = advance_pos(pos, "}")
      #(acc, rest, end_pos)
    }
    Ok(#(char, rest)) ->
      extract_until_close_brace(rest, acc <> char, advance_pos(pos, char))
  }
}

fn parse_binding(binding: String) -> #(String, Option(String)) {
  let binding = string.trim(binding)
  case string.split_once(binding, ",") {
    Ok(#(item, index)) -> #(string.trim(item), Some(string.trim(index)))
    Error(_) -> #(binding, None)
  }
}

fn extract_pattern(
  input: String,
  acc: String,
  pos: Position,
) -> Result(#(String, String, Position), ParseError) {
  case string.pop_grapheme(input) {
    Error(_) ->
      Error(ParseError(Span(start: pos, end: pos), "Unterminated pattern"))
    Ok(#("}", rest)) -> {
      let end_pos = advance_pos(pos, "}")
      Ok(#(acc, rest, end_pos))
    }
    Ok(#("(", rest)) -> {
      // Handle nested parens in pattern
      let new_pos = advance_pos(pos, "(")
      case extract_balanced_parens(rest, 0, "", new_pos) {
        Ok(#(inner, remaining, after_pos)) -> {
          extract_pattern(remaining, acc <> "(" <> inner <> ")", after_pos)
        }
        Error(err) -> Error(err)
      }
    }
    Ok(#(char, rest)) ->
      extract_pattern(rest, acc <> char, advance_pos(pos, char))
  }
}

// === Expression Extraction (with brace balancing) ===

fn extract_expression(
  input: String,
  depth: Int,
  acc: String,
  pos: Position,
) -> Result(#(String, String, Position), ParseError) {
  case string.pop_grapheme(input) {
    Error(_) ->
      Error(ParseError(
        Span(start: pos, end: pos),
        "Unexpected end of input while parsing expression",
      ))
    Ok(#("{", rest)) ->
      extract_expression(rest, depth + 1, acc <> "{", advance_pos(pos, "{"))
    Ok(#("}", rest)) -> {
      case depth {
        0 -> {
          let end_pos = advance_pos(pos, "}")
          Ok(#(acc, rest, end_pos))
        }
        _ ->
          extract_expression(rest, depth - 1, acc <> "}", advance_pos(pos, "}"))
      }
    }
    Ok(#("\"", rest)) -> {
      // Handle string literals to avoid counting braces inside strings
      let new_pos = advance_pos(pos, "\"")
      case extract_string_literal(rest, "", new_pos) {
        Ok(#(str, remaining, after_pos)) ->
          extract_expression(
            remaining,
            depth,
            acc <> "\"" <> str <> "\"",
            after_pos,
          )
        Error(err) -> Error(err)
      }
    }
    Ok(#("(", rest)) -> {
      // Handle parens to properly balance
      extract_expression(rest, depth, acc <> "(", advance_pos(pos, "("))
    }
    Ok(#(")", rest)) -> {
      extract_expression(rest, depth, acc <> ")", advance_pos(pos, ")"))
    }
    Ok(#(char, rest)) ->
      extract_expression(rest, depth, acc <> char, advance_pos(pos, char))
  }
}

fn extract_string_literal(
  input: String,
  acc: String,
  pos: Position,
) -> Result(#(String, String, Position), ParseError) {
  case string.pop_grapheme(input) {
    Error(_) ->
      Error(ParseError(
        Span(start: pos, end: pos),
        "Unterminated string literal",
      ))
    Ok(#("\\", rest)) -> {
      // Handle escape sequences
      case string.pop_grapheme(rest) {
        Ok(#(escaped, rest2)) -> {
          let new_pos = advance_pos(advance_pos(pos, "\\"), escaped)
          extract_string_literal(rest2, acc <> "\\" <> escaped, new_pos)
        }
        Error(_) ->
          Error(ParseError(
            Span(start: pos, end: pos),
            "Unterminated escape sequence",
          ))
      }
    }
    Ok(#("\"", rest)) -> {
      let end_pos = advance_pos(pos, "\"")
      Ok(#(acc, rest, end_pos))
    }
    Ok(#(char, rest)) ->
      extract_string_literal(rest, acc <> char, advance_pos(pos, char))
  }
}

// === Text Parsing ===

fn parse_text(
  input: String,
  acc: String,
  pos: Position,
) -> #(String, String, Position) {
  case input {
    // Escaped braces
    "{{" <> rest -> parse_text(rest, acc <> "{", advance_pos_str(pos, "{{"))
    "}}" <> rest -> parse_text(rest, acc <> "}", advance_pos_str(pos, "}}"))

    // Start of expression or control flow - stop here
    "{" <> _ -> #(acc, input, pos)

    // Start of HTML tag or comment - stop here
    "<" <> _ -> #(acc, input, pos)

    // Start of directive - stop here
    "@import" <> _ -> #(acc, input, pos)
    "@params" <> _ -> #(acc, input, pos)

    // Empty input
    "" -> #(acc, input, pos)

    // Regular character
    _ -> {
      case string.pop_grapheme(input) {
        Ok(#(char, rest)) ->
          parse_text(rest, acc <> char, advance_pos(pos, char))
        Error(_) -> #(acc, input, pos)
      }
    }
  }
}

// === HTML Comment Handling ===

fn skip_html_comment(
  input: String,
  pos: Position,
) -> Result(#(String, Position), ParseError) {
  case input {
    "" ->
      Error(ParseError(Span(start: pos, end: pos), "Unterminated HTML comment"))
    "-->" <> rest -> {
      let end_pos = advance_pos_str(pos, "-->")
      Ok(#(rest, end_pos))
    }
    _ -> {
      case string.pop_grapheme(input) {
        Ok(#(char, rest)) -> skip_html_comment(rest, advance_pos(pos, char))
        Error(_) ->
          Error(ParseError(
            Span(start: pos, end: pos),
            "Unterminated HTML comment",
          ))
      }
    }
  }
}

// === Utility Functions ===

fn is_whitespace_only(text: String) -> Bool {
  text
  |> string.to_graphemes()
  |> list.all(fn(c) { c == " " || c == "\t" || c == "\n" || c == "\r" })
}

fn skip_whitespace(input: String, pos: Position) -> #(String, Position) {
  case string.pop_grapheme(input) {
    Ok(#(" ", rest)) -> skip_whitespace(rest, advance_pos(pos, " "))
    Ok(#("\t", rest)) -> skip_whitespace(rest, advance_pos(pos, "\t"))
    Ok(#("\n", rest)) -> skip_whitespace(rest, advance_pos(pos, "\n"))
    Ok(#("\r", rest)) -> skip_whitespace(rest, advance_pos(pos, "\r"))
    _ -> #(input, pos)
  }
}

fn extract_balanced_parens(
  input: String,
  depth: Int,
  acc: String,
  pos: Position,
) -> Result(#(String, String, Position), ParseError) {
  case string.pop_grapheme(input) {
    Error(_) ->
      Error(ParseError(Span(start: pos, end: pos), "Unterminated parentheses"))
    Ok(#("(", rest)) ->
      extract_balanced_parens(
        rest,
        depth + 1,
        acc <> "(",
        advance_pos(pos, "("),
      )
    Ok(#(")", rest)) -> {
      case depth {
        0 -> {
          let end_pos = advance_pos(pos, ")")
          Ok(#(acc, rest, end_pos))
        }
        _ ->
          extract_balanced_parens(
            rest,
            depth - 1,
            acc <> ")",
            advance_pos(pos, ")"),
          )
      }
    }
    Ok(#("\"", rest)) -> {
      // Handle string literals
      let new_pos = advance_pos(pos, "\"")
      case extract_string_literal(rest, "", new_pos) {
        Ok(#(str, remaining, after_pos)) ->
          extract_balanced_parens(
            remaining,
            depth,
            acc <> "\"" <> str <> "\"",
            after_pos,
          )
        Error(err) -> Error(err)
      }
    }
    Ok(#(char, rest)) ->
      extract_balanced_parens(rest, depth, acc <> char, advance_pos(pos, char))
  }
}

// === Main Parse Function ===

/// Parse a template string into a Template AST
pub fn parse(input: String) -> ParseResult(Template) {
  case tokenize(input) {
    Error(errors) -> Error(errors)
    Ok(tokens) -> {
      let #(imports, params, body_tokens) = extract_metadata(tokens)
      case build_ast(body_tokens, [], []) {
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
fn build_ast(
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
          build_ast(rest, stack, errors)
        }

        // HTML opening tag - push new frame
        HtmlOpen(tag: tag, attrs: attrs, self_closing: False, span: span) -> {
          let frame =
            ElementFrame(tag: tag, attrs: attrs, children: [], span: span)
          build_ast(rest, [frame, ..stack], errors)
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
                  build_ast(rest, new_stack, errors)
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
                  build_ast(rest, stack, [error, ..errors])
                }
              }
            }
            _ -> {
              let error =
                ParseError(
                  close_span,
                  "Unexpected closing tag </" <> close_tag <> ">",
                )
              build_ast(rest, stack, [error, ..errors])
            }
          }
        }

        // Text content
        Text(content: content, span: span) -> {
          let node = TextNode(content: content, span: span)
          let stack = add_node_to_stack(node, stack)
          build_ast(rest, stack, errors)
        }

        // Expression
        Expr(content: content, span: span) -> {
          let node = ExprNode(expr: content, span: span)
          let stack = add_node_to_stack(node, stack)
          build_ast(rest, stack, errors)
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
          build_ast(rest, [frame, ..stack], errors)
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
              build_ast(rest, [new_frame, ..rest_stack], errors)
            }
            _ -> {
              let error =
                ParseError(else_span, "{:else} without matching {#if}")
              build_ast(rest, stack, [error, ..errors])
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
              build_ast(rest, new_stack, errors)
            }
            _ -> {
              let error = ParseError(end_span, "{/if} without matching {#if}")
              build_ast(rest, stack, [error, ..errors])
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
          build_ast(rest, [frame, ..stack], errors)
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
              build_ast(rest, new_stack, errors)
            }
            _ -> {
              let error =
                ParseError(end_span, "{/each} without matching {#each}")
              build_ast(rest, stack, [error, ..errors])
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
          build_ast(rest, [frame, ..stack], errors)
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
              build_ast(rest, [new_frame, ..rest_stack], errors)
            }
            _ -> {
              let error =
                ParseError(pattern_span, "Case pattern outside of {#case}")
              build_ast(rest, stack, [error, ..errors])
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
              build_ast(rest, new_stack, errors)
            }
            _ -> {
              let error =
                ParseError(end_span, "{/case} without matching {#case}")
              build_ast(rest, stack, [error, ..errors])
            }
          }
        }

        // Comment (skip)
        types.Comment(span: _) -> {
          build_ast(rest, stack, errors)
        }

        // Import and Params should have been extracted already
        Import(content: _, span: _) -> {
          build_ast(rest, stack, errors)
        }

        Params(params: _, span: _) -> {
          build_ast(rest, stack, errors)
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

import ghtml/parser
import ghtml/types.{
  CaseNode, EachNode, Element, ExprNode, IfNode, ParseError, Position, Span,
  TextNode,
}
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should

// === Basic Element Tests ===

pub fn parse_single_element_test() {
  let input = "<div></div>"
  let assert Ok(template) = parser.parse(input)

  should.equal(list.length(template.body), 1)
  case list.first(template.body) {
    Ok(Element(tag, attrs, children, _)) -> {
      should.equal(tag, "div")
      should.equal(attrs, [])
      should.equal(children, [])
    }
    _ -> should.fail()
  }
}

pub fn parse_nested_elements_test() {
  let input = "<div><span></span></div>"
  let assert Ok(template) = parser.parse(input)

  case list.first(template.body) {
    Ok(Element(tag, _, children, _)) -> {
      should.equal(tag, "div")
      should.equal(list.length(children), 1)
      case list.first(children) {
        Ok(Element(inner_tag, _, _, _)) -> should.equal(inner_tag, "span")
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn parse_deeply_nested_test() {
  let input = "<div><section><article><p></p></article></section></div>"
  let assert Ok(template) = parser.parse(input)

  // Verify structure depth
  case template.body {
    [
      Element(
        "div",
        _,
        [
          Element(
            "section",
            _,
            [Element("article", _, [Element("p", _, [], _)], _)],
            _,
          ),
        ],
        _,
      ),
    ] -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn parse_self_closing_element_test() {
  let input = "<div><br /><input /></div>"
  let assert Ok(template) = parser.parse(input)

  case list.first(template.body) {
    Ok(Element(_, _, children, _)) -> {
      should.equal(list.length(children), 2)
    }
    _ -> should.fail()
  }
}

pub fn parse_sibling_elements_test() {
  let input = "<div></div><span></span><p></p>"
  let assert Ok(template) = parser.parse(input)

  should.equal(list.length(template.body), 3)
}

// === Text and Expression Tests ===

pub fn parse_text_content_test() {
  let input = "<div>Hello, World!</div>"
  let assert Ok(template) = parser.parse(input)

  case template.body {
    [Element(_, _, [TextNode(content, _)], _)] -> {
      should.be_true(string.contains(content, "Hello"))
    }
    _ -> should.fail()
  }
}

pub fn parse_expression_content_test() {
  let input = "<div>{user.name}</div>"
  let assert Ok(template) = parser.parse(input)

  case template.body {
    [Element(_, _, children, _)] -> {
      should.be_true(
        list.any(children, fn(n) {
          case n {
            ExprNode(expr, _) -> expr == "user.name"
            _ -> False
          }
        }),
      )
    }
    _ -> should.fail()
  }
}

pub fn parse_mixed_text_and_expressions_test() {
  let input = "<div>Hello, {name}!</div>"
  let assert Ok(template) = parser.parse(input)

  case template.body {
    [Element(_, _, children, _)] -> {
      // Should have text, expr, text
      should.be_true(list.length(children) >= 2)
    }
    _ -> should.fail()
  }
}

// === If/Else Tests ===

pub fn parse_if_node_test() {
  let input = "<div>{#if show}visible{/if}</div>"
  let assert Ok(template) = parser.parse(input)

  case template.body {
    [Element(_, _, [IfNode(condition, then_branch, else_branch, _)], _)] -> {
      should.equal(condition, "show")
      should.equal(list.length(then_branch), 1)
      should.equal(else_branch, [])
    }
    _ -> should.fail()
  }
}

pub fn parse_if_else_node_test() {
  let input = "{#if show}<div>yes</div>{:else}<span>no</span>{/if}"
  let assert Ok(template) = parser.parse(input)

  case template.body {
    [IfNode(condition, then_branch, else_branch, _)] -> {
      should.equal(condition, "show")
      should.equal(list.length(then_branch), 1)
      should.equal(list.length(else_branch), 1)
    }
    _ -> should.fail()
  }
}

pub fn parse_nested_if_test() {
  let input = "{#if a}{#if b}inner{/if}{/if}"
  let assert Ok(template) = parser.parse(input)

  case template.body {
    [IfNode(_, [IfNode(_, _, _, _)], _, _)] -> should.be_true(True)
    _ -> should.fail()
  }
}

// === Each Tests ===

pub fn parse_each_node_test() {
  let input = "{#each items as item}<li>{item}</li>{/each}"
  let assert Ok(template) = parser.parse(input)

  case template.body {
    [EachNode(collection, item, index, body, _)] -> {
      should.equal(collection, "items")
      should.equal(item, "item")
      should.equal(index, None)
      should.equal(list.length(body), 1)
    }
    _ -> should.fail()
  }
}

pub fn parse_each_with_index_test() {
  let input = "{#each items as item, i}<li>{i}: {item}</li>{/each}"
  let assert Ok(template) = parser.parse(input)

  case template.body {
    [EachNode(_, _, index, _, _)] -> {
      should.equal(index, Some("i"))
    }
    _ -> should.fail()
  }
}

// === Case Tests ===

pub fn parse_case_node_test() {
  let input =
    "{#case result}{:Ok(x)}<span>{x}</span>{:Error(e)}<span>{e}</span>{/case}"
  let assert Ok(template) = parser.parse(input)

  case template.body {
    [CaseNode(expr, branches, _)] -> {
      should.equal(expr, "result")
      should.equal(list.length(branches), 2)
    }
    _ -> should.fail()
  }
}

pub fn parse_case_multiple_branches_test() {
  let input = "{#case status}{:Pending}..{:Active}ok{:Completed}done{/case}"
  let assert Ok(template) = parser.parse(input)

  case template.body {
    [CaseNode(_, branches, _)] -> {
      should.equal(list.length(branches), 3)
    }
    _ -> should.fail()
  }
}

// === Metadata Tests ===

pub fn parse_imports_test() {
  let input =
    "@import(gleam/io)
@import(gleam/list.{map, filter})

<div></div>"
  let assert Ok(template) = parser.parse(input)

  should.equal(list.length(template.imports), 2)
  should.equal(list.first(template.imports), Ok("gleam/io"))
}

pub fn parse_params_test() {
  let input =
    "@params(name: String, count: Int)

<div>{name}</div>"
  let assert Ok(template) = parser.parse(input)

  should.equal(list.length(template.params), 2)
  should.equal(list.first(template.params), Ok(#("name", "String")))
}

pub fn parse_full_template_test() {
  let input =
    "@import(gleam/int)
@import(app/types.{type User})

@params(user: User, count: Int)

<div class=\"card\">
  <h1>{user.name}</h1>
  <p>Count: {int.to_string(count)}</p>
</div>"
  let assert Ok(template) = parser.parse(input)

  should.equal(list.length(template.imports), 2)
  should.equal(list.length(template.params), 2)
  should.equal(list.length(template.body), 1)
}

// === Error Handling Tests ===

pub fn parse_unclosed_element_error_test() {
  let input = "<div><span></div>"
  let result = parser.parse(input)

  case result {
    Error(errors) -> {
      should.be_true(errors != [])
      // Error should mention the mismatched tag
    }
    Ok(_) -> should.fail()
  }
}

pub fn parse_unclosed_if_error_test() {
  let input = "{#if show}<div></div>"
  let result = parser.parse(input)

  case result {
    Error(errors) -> should.be_true(errors != [])
    Ok(_) -> should.fail()
  }
}

pub fn parse_unclosed_each_error_test() {
  let input = "{#each items as item}<li></li>"
  let result = parser.parse(input)

  case result {
    Error(errors) -> should.be_true(errors != [])
    Ok(_) -> should.fail()
  }
}

pub fn parse_else_without_if_error_test() {
  let input = "<div>{:else}</div>"
  let result = parser.parse(input)

  case result {
    Error(errors) -> should.be_true(errors != [])
    Ok(_) -> should.fail()
  }
}

// === Whitespace Handling Tests ===

pub fn parse_whitespace_between_elements_test() {
  let input =
    "<div>
  <span>text</span>
</div>"
  let assert Ok(template) = parser.parse(input)

  // Whitespace-only text nodes may be preserved or collapsed
  // The important thing is the structure is correct
  case template.body {
    [Element("div", _, children, _)] -> {
      should.be_true(
        list.any(children, fn(n) {
          case n {
            Element("span", _, _, _) -> True
            _ -> False
          }
        }),
      )
    }
    _ -> should.fail()
  }
}

// === Error Formatting Tests ===

pub fn format_error_test() {
  let source =
    "line 1
line 2
line 3 {broken"

  let error =
    ParseError(
      span: Span(
        start: Position(line: 3, column: 8),
        end: Position(line: 3, column: 8),
      ),
      message: "Unclosed expression",
    )

  let formatted = parser.format_error(error, source)

  should.be_true(string.contains(formatted, "line 3"))
  should.be_true(string.contains(formatted, "Unclosed expression"))
}

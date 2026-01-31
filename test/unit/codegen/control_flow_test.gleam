import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import lustre_template_gen/codegen
import lustre_template_gen/types.{
  type Span, CaseBranch, CaseNode, EachNode, Element, ExprNode, IfNode, Position,
  Span, Template, TextNode,
}

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === If Node Tests ===

pub fn generate_if_true_only_test() {
  let template =
    Template(imports: [], params: [], body: [
      IfNode(
        condition: "show",
        then_branch: [TextNode("Visible", test_span())],
        else_branch: [],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "case show {"))
  should.be_true(string.contains(code, "True ->"))
  should.be_true(string.contains(code, "False -> none()"))
}

pub fn generate_if_else_test() {
  let template =
    Template(imports: [], params: [], body: [
      IfNode(
        condition: "active",
        then_branch: [TextNode("Active", test_span())],
        else_branch: [TextNode("Inactive", test_span())],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "case active {"))
  should.be_true(string.contains(code, "True ->"))
  should.be_true(string.contains(code, "False ->"))
  should.be_true(string.contains(code, "text(\"Active\")"))
  should.be_true(string.contains(code, "text(\"Inactive\")"))
}

pub fn generate_if_with_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      IfNode(
        condition: "show",
        then_branch: [
          Element("div", [], [TextNode("Content", test_span())], test_span()),
        ],
        else_branch: [],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div("))
}

pub fn generate_if_with_complex_condition_test() {
  let template =
    Template(imports: [], params: [], body: [
      IfNode(
        condition: "user.is_admin && count > 0",
        then_branch: [TextNode("Yes", test_span())],
        else_branch: [],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "case user.is_admin && count > 0 {"))
}

pub fn generate_if_multiple_children_test() {
  let template =
    Template(imports: [], params: [], body: [
      IfNode(
        condition: "show",
        then_branch: [
          Element("div", [], [], test_span()),
          Element("span", [], [], test_span()),
        ],
        else_branch: [],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Multiple children should use fragment
  should.be_true(string.contains(code, "fragment("))
}

pub fn generate_nested_if_test() {
  let template =
    Template(imports: [], params: [], body: [
      IfNode(
        condition: "a",
        then_branch: [
          IfNode(
            condition: "b",
            then_branch: [TextNode("Both", test_span())],
            else_branch: [],
            span: test_span(),
          ),
        ],
        else_branch: [],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Should have nested case expressions
  let case_count = string.split(code, "case ") |> list.length()
  should.be_true(case_count >= 3)
  // At least 2 case statements
}

// === Each Node Tests ===

pub fn generate_each_without_index_test() {
  let template =
    Template(imports: [], params: [], body: [
      EachNode(
        collection: "items",
        item: "item",
        index: None,
        body: [
          Element("li", [], [ExprNode("item.name", test_span())], test_span()),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "keyed.fragment("))
  should.be_true(string.contains(code, "list.map(items"))
  should.be_true(string.contains(code, "fn(item)"))
}

pub fn generate_each_with_index_test() {
  let template =
    Template(imports: [], params: [], body: [
      EachNode(
        collection: "items",
        item: "item",
        index: Some("i"),
        body: [
          Element("li", [], [ExprNode("item", test_span())], test_span()),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "keyed.fragment("))
  should.be_true(string.contains(code, "list.index_map(items"))
  should.be_true(string.contains(code, "fn(item, i)"))
}

pub fn generate_each_with_complex_body_test() {
  let template =
    Template(imports: [], params: [], body: [
      EachNode(
        collection: "users",
        item: "user",
        index: None,
        body: [
          Element(
            "div",
            [],
            [
              Element(
                "h2",
                [],
                [ExprNode("user.name", test_span())],
                test_span(),
              ),
              Element(
                "p",
                [],
                [ExprNode("user.email", test_span())],
                test_span(),
              ),
            ],
            test_span(),
          ),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "html.h2("))
  should.be_true(string.contains(code, "html.p("))
}

pub fn generate_nested_each_test() {
  let template =
    Template(imports: [], params: [], body: [
      EachNode(
        collection: "groups",
        item: "group",
        index: None,
        body: [
          Element(
            "div",
            [],
            [
              EachNode(
                collection: "group.items",
                item: "item",
                index: None,
                body: [Element("span", [], [], test_span())],
                span: test_span(),
              ),
            ],
            test_span(),
          ),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Should have nested keyed/list.map
  let keyed_count = string.split(code, "keyed.fragment(") |> list.length()
  should.be_true(keyed_count >= 3)
  // At least 2 keyed.fragment calls
}

// === Case Node Tests ===

pub fn generate_case_two_branches_test() {
  let template =
    Template(imports: [], params: [], body: [
      CaseNode(
        expr: "result",
        branches: [
          CaseBranch("Ok(value)", [ExprNode("value", test_span())], test_span()),
          CaseBranch("Error(e)", [TextNode("Error", test_span())], test_span()),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "case result {"))
  should.be_true(string.contains(code, "Ok(value) ->"))
  should.be_true(string.contains(code, "Error(e) ->"))
}

pub fn generate_case_with_wildcard_test() {
  let template =
    Template(imports: [], params: [], body: [
      CaseNode(
        expr: "status",
        branches: [
          CaseBranch("Active", [TextNode("Active", test_span())], test_span()),
          CaseBranch("_", [TextNode("Other", test_span())], test_span()),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "_ ->"))
}

pub fn generate_case_with_complex_patterns_test() {
  let template =
    Template(imports: [], params: [], body: [
      CaseNode(
        expr: "user.role",
        branches: [
          CaseBranch("Admin", [TextNode("Admin", test_span())], test_span()),
          CaseBranch(
            "Member(since)",
            [ExprNode("since", test_span())],
            test_span(),
          ),
          CaseBranch("Guest", [TextNode("Guest", test_span())], test_span()),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "Admin ->"))
  should.be_true(string.contains(code, "Member(since) ->"))
  should.be_true(string.contains(code, "Guest ->"))
}

pub fn generate_case_with_tuple_pattern_test() {
  let template =
    Template(imports: [], params: [], body: [
      CaseNode(
        expr: "data",
        branches: [
          CaseBranch("#(a, b)", [ExprNode("a", test_span())], test_span()),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "#(a, b) ->"))
}

pub fn generate_case_with_element_body_test() {
  let template =
    Template(imports: [], params: [], body: [
      CaseNode(
        expr: "result",
        branches: [
          CaseBranch(
            "Ok(x)",
            [Element("div", [], [ExprNode("x", test_span())], test_span())],
            test_span(),
          ),
          CaseBranch(
            "Error(_)",
            [Element("span", [], [TextNode("Error", test_span())], test_span())],
            test_span(),
          ),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "html.span("))
}

// === Combined Control Flow Tests ===

pub fn generate_if_inside_each_test() {
  let template =
    Template(imports: [], params: [], body: [
      EachNode(
        collection: "items",
        item: "item",
        index: None,
        body: [
          IfNode(
            condition: "item.visible",
            then_branch: [Element("div", [], [], test_span())],
            else_branch: [],
            span: test_span(),
          ),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "list.map("))
  should.be_true(string.contains(code, "case item.visible {"))
}

pub fn generate_case_inside_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [],
        [
          CaseNode(
            expr: "status",
            branches: [
              CaseBranch("Ok(_)", [TextNode("OK", test_span())], test_span()),
              CaseBranch(
                "Error(_)",
                [TextNode("Error", test_span())],
                test_span(),
              ),
            ],
            span: test_span(),
          ),
        ],
        test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "case status {"))
}

// === Fragment Tests ===

pub fn generate_fragment_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
      Element("span", [], [], test_span()),
      Element("p", [], [], test_span()),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "fragment("))
}

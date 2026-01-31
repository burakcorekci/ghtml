# Task 009: Code Generation - Control Flow

## Description
Extend the codegen module to handle control flow nodes: `{#if}`, `{#each}`, and `{#case}`. This includes generating proper Gleam `case` expressions and list operations.

## Dependencies
- Task 007: Code Generation - Basic Elements
- Task 008: Code Generation - Attributes

## Success Criteria
1. `IfNode` generates Gleam `case condition { True -> ... False -> ... }` expressions
2. `IfNode` without else branch generates `case ... { True -> ... False -> none() }`
3. `EachNode` generates `keyed(...)` with `list.index_map`
4. `EachNode` without index still works correctly
5. `CaseNode` generates proper Gleam `case expr { pattern -> ... }` expressions
6. Nested control flow works correctly
7. Control flow can contain elements, text, and expressions

## Implementation Steps

### 1. Implement IfNode generation
```gleam
fn generate_if_node(
  condition: String,
  then_branch: List(Node),
  else_branch: List(Node),
  indent: Int,
) -> String {
  let ind = make_indent(indent)
  let then_code = generate_branch_content(then_branch, indent + 1)
  let else_code = case else_branch {
    [] -> make_indent(indent + 1) <> "none()"
    _ -> generate_branch_content(else_branch, indent + 1)
  }

  ind <> "case " <> condition <> " {\n"
  <> make_indent(indent + 1) <> "True -> " <> then_code <> "\n"
  <> make_indent(indent + 1) <> "False -> " <> else_code <> "\n"
  <> ind <> "}"
}

fn generate_branch_content(nodes: List(Node), indent: Int) -> String {
  case nodes {
    [] -> "none()"
    [single] -> generate_node(single, 0)  // Single node, no wrapper
    multiple -> {
      let children = generate_children(multiple, indent)
      "fragment([\n" <> children <> "\n" <> make_indent(indent) <> "])"
    }
  }
}
```

### 2. Implement EachNode generation
```gleam
fn generate_each_node(
  collection: String,
  item: String,
  index: Option(String),
  body: List(Node),
  indent: Int,
) -> String {
  let ind = make_indent(indent)

  case index {
    None -> {
      // No index: list.map with keyed
      let body_code = generate_branch_content(body, indent + 2)
      ind <> "keyed(\n"
      <> make_indent(indent + 1) <> "list.map(" <> collection <> ", fn(" <> item <> ") {\n"
      <> make_indent(indent + 2) <> "#(" <> item <> ".id, " <> body_code <> ")\n"
      <> make_indent(indent + 1) <> "})\n"
      <> ind <> ")"
    }
    Some(idx) -> {
      // With index: list.index_map with keyed
      let body_code = generate_branch_content(body, indent + 2)
      ind <> "keyed(\n"
      <> make_indent(indent + 1) <> "list.index_map(" <> collection <> ", fn(" <> item <> ", " <> idx <> ") {\n"
      <> make_indent(indent + 2) <> "#(int.to_string(" <> idx <> "), " <> body_code <> ")\n"
      <> make_indent(indent + 1) <> "})\n"
      <> ind <> ")"
    }
  }
}
```

### 3. Implement CaseNode generation
```gleam
fn generate_case_node(
  expr: String,
  branches: List(CaseBranch),
  indent: Int,
) -> String {
  let ind = make_indent(indent)

  let branches_code = branches
  |> list.map(fn(branch) {
    let body_code = generate_branch_content(branch.body, indent + 2)
    make_indent(indent + 1) <> branch.pattern <> " -> " <> body_code
  })
  |> string.join("\n")

  ind <> "case " <> expr <> " {\n"
  <> branches_code <> "\n"
  <> ind <> "}"
}
```

### 4. Update generate_node to handle control flow
```gleam
fn generate_node(node: Node, indent: Int) -> String {
  case node {
    Element(tag, attrs, children, _) -> generate_element(tag, attrs, children, indent)
    TextNode(content, _) -> generate_text(content, indent)
    ExprNode(expr, _) -> generate_expr(expr, indent)
    IfNode(condition, then_branch, else_branch, _) ->
      generate_if_node(condition, then_branch, else_branch, indent)
    EachNode(collection, item, index, body, _) ->
      generate_each_node(collection, item, index, body, indent)
    CaseNode(expr, branches, _) ->
      generate_case_node(expr, branches, indent)
    Fragment(children, _) ->
      generate_fragment(children, indent)
  }
}
```

### 5. Implement Fragment generation
```gleam
fn generate_fragment(children: List(Node), indent: Int) -> String {
  let ind = make_indent(indent)
  let children_code = generate_children(children, indent + 1)
  ind <> "fragment([\n" <> children_code <> "\n" <> ind <> "])"
}
```

## Test Cases

### Test File: `test/codegen_control_flow_test.gleam`

```gleam
import gleeunit/should
import lustre_template_gen/codegen
import lustre_template_gen/types.{
  Template, Element, TextNode, ExprNode, IfNode, EachNode, CaseNode, CaseBranch,
  Position, Span,
}
import gleam/string
import gleam/option.{Some, None}

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === If Node Tests ===

pub fn generate_if_true_only_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [IfNode(
      condition: "show",
      then_branch: [TextNode("Visible", test_span())],
      else_branch: [],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "case show {"))
  should.be_true(string.contains(code, "True ->"))
  should.be_true(string.contains(code, "False -> none()"))
}

pub fn generate_if_else_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [IfNode(
      condition: "active",
      then_branch: [TextNode("Active", test_span())],
      else_branch: [TextNode("Inactive", test_span())],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "case active {"))
  should.be_true(string.contains(code, "True ->"))
  should.be_true(string.contains(code, "False ->"))
  should.be_true(string.contains(code, "text(\"Active\")"))
  should.be_true(string.contains(code, "text(\"Inactive\")"))
}

pub fn generate_if_with_element_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [IfNode(
      condition: "show",
      then_branch: [Element("div", [], [TextNode("Content", test_span())], test_span())],
      else_branch: [],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div("))
}

pub fn generate_if_with_complex_condition_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [IfNode(
      condition: "user.is_admin && count > 0",
      then_branch: [TextNode("Yes", test_span())],
      else_branch: [],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "case user.is_admin && count > 0 {"))
}

pub fn generate_if_multiple_children_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [IfNode(
      condition: "show",
      then_branch: [
        Element("div", [], [], test_span()),
        Element("span", [], [], test_span()),
      ],
      else_branch: [],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Multiple children should use fragment
  should.be_true(string.contains(code, "fragment("))
}

pub fn generate_nested_if_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [IfNode(
      condition: "a",
      then_branch: [IfNode(
        condition: "b",
        then_branch: [TextNode("Both", test_span())],
        else_branch: [],
        span: test_span(),
      )],
      else_branch: [],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Should have nested case expressions
  let case_count = string.split(code, "case ") |> list.length()
  should.be_true(case_count >= 3)  // At least 2 case statements
}

// === Each Node Tests ===

pub fn generate_each_without_index_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [EachNode(
      collection: "items",
      item: "item",
      index: None,
      body: [Element("li", [], [ExprNode("item.name", test_span())], test_span())],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "keyed("))
  should.be_true(string.contains(code, "list.map(items"))
  should.be_true(string.contains(code, "fn(item)"))
}

pub fn generate_each_with_index_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [EachNode(
      collection: "items",
      item: "item",
      index: Some("i"),
      body: [Element("li", [], [ExprNode("item", test_span())], test_span())],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "keyed("))
  should.be_true(string.contains(code, "list.index_map(items"))
  should.be_true(string.contains(code, "fn(item, i)"))
}

pub fn generate_each_with_complex_body_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [EachNode(
      collection: "users",
      item: "user",
      index: None,
      body: [
        Element("div", [], [
          Element("h2", [], [ExprNode("user.name", test_span())], test_span()),
          Element("p", [], [ExprNode("user.email", test_span())], test_span()),
        ], test_span()),
      ],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "html.h2("))
  should.be_true(string.contains(code, "html.p("))
}

pub fn generate_nested_each_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [EachNode(
      collection: "groups",
      item: "group",
      index: None,
      body: [Element("div", [], [
        EachNode(
          collection: "group.items",
          item: "item",
          index: None,
          body: [Element("span", [], [], test_span())],
          span: test_span(),
        ),
      ], test_span())],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Should have nested keyed/list.map
  let keyed_count = string.split(code, "keyed(") |> list.length()
  should.be_true(keyed_count >= 3)  // At least 2 keyed calls
}

// === Case Node Tests ===

pub fn generate_case_two_branches_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [CaseNode(
      expr: "result",
      branches: [
        CaseBranch("Ok(value)", [ExprNode("value", test_span())], test_span()),
        CaseBranch("Error(e)", [TextNode("Error", test_span())], test_span()),
      ],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "case result {"))
  should.be_true(string.contains(code, "Ok(value) ->"))
  should.be_true(string.contains(code, "Error(e) ->"))
}

pub fn generate_case_with_wildcard_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [CaseNode(
      expr: "status",
      branches: [
        CaseBranch("Active", [TextNode("Active", test_span())], test_span()),
        CaseBranch("_", [TextNode("Other", test_span())], test_span()),
      ],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "_ ->"))
}

pub fn generate_case_with_complex_patterns_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [CaseNode(
      expr: "user.role",
      branches: [
        CaseBranch("Admin", [TextNode("Admin", test_span())], test_span()),
        CaseBranch("Member(since)", [ExprNode("since", test_span())], test_span()),
        CaseBranch("Guest", [TextNode("Guest", test_span())], test_span()),
      ],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "Admin ->"))
  should.be_true(string.contains(code, "Member(since) ->"))
  should.be_true(string.contains(code, "Guest ->"))
}

pub fn generate_case_with_tuple_pattern_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [CaseNode(
      expr: "data",
      branches: [
        CaseBranch("#(a, b)", [ExprNode("a", test_span())], test_span()),
      ],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "#(a, b) ->"))
}

pub fn generate_case_with_element_body_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [CaseNode(
      expr: "result",
      branches: [
        CaseBranch("Ok(x)", [
          Element("div", [], [ExprNode("x", test_span())], test_span()),
        ], test_span()),
        CaseBranch("Error(_)", [
          Element("span", [], [TextNode("Error", test_span())], test_span()),
        ], test_span()),
      ],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "html.span("))
}

// === Combined Control Flow Tests ===

pub fn generate_if_inside_each_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [EachNode(
      collection: "items",
      item: "item",
      index: None,
      body: [IfNode(
        condition: "item.visible",
        then_branch: [Element("div", [], [], test_span())],
        else_branch: [],
        span: test_span(),
      )],
      span: test_span(),
    )],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "list.map("))
  should.be_true(string.contains(code, "case item.visible {"))
}

pub fn generate_case_inside_element_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [
      CaseNode(
        expr: "status",
        branches: [
          CaseBranch("Ok(_)", [TextNode("OK", test_span())], test_span()),
          CaseBranch("Error(_)", [TextNode("Error", test_span())], test_span()),
        ],
        span: test_span(),
      ),
    ], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "case status {"))
}

// === Fragment Tests ===

pub fn generate_fragment_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [
      Element("div", [], [], test_span()),
      Element("span", [], [], test_span()),
      Element("p", [], [], test_span()),
    ],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "fragment("))
}
```

## Verification Checklist
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes all control flow tests
- [ ] If/else generates correct case expressions
- [ ] If without else uses `none()`
- [ ] Each generates keyed with list operations
- [ ] Each with/without index both work
- [ ] Case generates proper pattern matching
- [ ] Nested control flow works
- [ ] Multiple children use fragment

## Notes
- Control flow nodes generate Gleam expressions, not statements
- The `keyed` function improves performance for dynamic lists
- Fragment is needed when a branch has multiple sibling nodes
- Consider edge cases like empty branches

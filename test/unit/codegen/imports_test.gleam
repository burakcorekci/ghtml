import ghtml/codegen
import ghtml/types.{
  type Span, CaseBranch, CaseNode, EachNode, Element, EventAttr, IfNode,
  Position, Span, StaticAttr, Template, TextNode,
}
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === Basic Import Tests ===

pub fn generate_minimal_imports_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [TextNode("Hello", test_span())], test_span()),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Should have basic lustre imports
  should.be_true(string.contains(code, "import lustre/element.{"))
  should.be_true(string.contains(code, "import lustre/element/html"))

  // Should NOT have these (not needed)
  should.be_false(string.contains(code, "import gleam/list"))
  should.be_false(string.contains(code, "import lustre/event"))
  should.be_false(string.contains(code, "keyed"))
  should.be_false(string.contains(code, "none"))
  should.be_false(string.contains(code, "fragment"))
}

pub fn generate_imports_with_user_imports_test() {
  let template =
    Template(imports: ["gleam/io", "app/types.{type User}"], params: [], body: [
      Element("div", [], [], test_span()),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "import gleam/io"))
  should.be_true(string.contains(code, "import app/types.{type User}"))
}

// === Feature-Based Import Tests ===

pub fn generate_imports_with_if_else_test() {
  let template =
    Template(imports: [], params: [], body: [
      IfNode(
        condition: "show",
        then_branch: [TextNode("Yes", test_span())],
        else_branch: [TextNode("No", test_span())],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Has else, so none is NOT needed
  should.be_false(string.contains(code, "none"))
}

pub fn generate_imports_with_if_no_else_test() {
  let template =
    Template(imports: [], params: [], body: [
      IfNode(
        condition: "show",
        then_branch: [TextNode("Yes", test_span())],
        else_branch: [],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // No else, so none IS needed
  should.be_true(string.contains(code, "none"))
}

pub fn generate_imports_with_each_test() {
  let template =
    Template(imports: [], params: [], body: [
      EachNode(
        collection: "items",
        item: "item",
        index: None,
        body: [Element("li", [], [], test_span())],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Each requires list and keyed
  should.be_true(string.contains(code, "import gleam/list"))
  should.be_true(string.contains(code, "keyed"))
}

pub fn generate_imports_with_each_index_test() {
  let template =
    Template(imports: [], params: [], body: [
      EachNode(
        collection: "items",
        item: "item",
        index: Some("i"),
        body: [Element("li", [], [], test_span())],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Each with index requires gleam/int for int.to_string
  should.be_true(string.contains(code, "import gleam/int"))
}

pub fn generate_imports_with_event_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("button", [EventAttr("click", "on_click")], [], test_span()),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Event handlers require lustre/event
  should.be_true(string.contains(code, "import lustre/event"))
}

pub fn generate_imports_without_event_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("button", [StaticAttr("class", "btn")], [], test_span()),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // No event handlers, no lustre/event
  should.be_false(string.contains(code, "import lustre/event"))
}

pub fn generate_imports_with_fragment_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
      Element("span", [], [], test_span()),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Multiple roots require fragment
  should.be_true(string.contains(code, "fragment"))
}

pub fn generate_imports_single_root_no_fragment_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Single root, no fragment needed
  should.be_false(string.contains(code, "fragment"))
}

// === Conflict Handling Tests ===

pub fn generate_imports_no_duplicate_list_test() {
  let template =
    Template(imports: ["gleam/list.{map, filter}"], params: [], body: [
      EachNode(
        collection: "items",
        item: "item",
        index: None,
        body: [Element("li", [], [], test_span())],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Should have user's import
  should.be_true(string.contains(code, "import gleam/list.{map, filter}"))

  // Should NOT have duplicate auto-import
  let list_import_count =
    code
    |> string.split("import gleam/list")
    |> list.length()
  should.equal(list_import_count, 2)
  // Split creates 2 parts for 1 occurrence
}

pub fn generate_imports_no_duplicate_int_test() {
  let template =
    Template(imports: ["gleam/int"], params: [], body: [
      EachNode(
        collection: "items",
        item: "item",
        index: Some("i"),
        body: [Element("li", [], [], test_span())],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Should have user's import
  should.be_true(string.contains(code, "import gleam/int"))

  // Should NOT have duplicate
  let int_import_count =
    code
    |> string.split("import gleam/int")
    |> list.length()
  should.equal(int_import_count, 2)
  // 1 occurrence
}

// === Combined Feature Tests ===

pub fn generate_imports_all_features_test() {
  let template =
    Template(imports: ["app/types.{type User}"], params: [], body: [
      Element("div", [], [], test_span()),
      Element("button", [EventAttr("click", "on_click")], [], test_span()),
      IfNode("show", [TextNode("Yes", test_span())], [], test_span()),
      EachNode(
        "items",
        "item",
        Some("i"),
        [Element("li", [], [], test_span())],
        test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // All features should be present
  should.be_true(string.contains(code, "import gleam/list"))
  should.be_true(string.contains(code, "import gleam/int"))
  should.be_true(string.contains(code, "import lustre/event"))
  should.be_true(string.contains(code, "keyed"))
  should.be_true(string.contains(code, "none"))
  should.be_true(string.contains(code, "fragment"))
  should.be_true(string.contains(code, "import app/types.{type User}"))
}

// === Import Order Tests ===

pub fn generate_imports_correct_order_test() {
  let template =
    Template(imports: ["app/types"], params: [], body: [
      EachNode(
        "items",
        "item",
        None,
        [Element("li", [], [], test_span())],
        test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Auto imports should come before user imports
  let list_pos = string.split(code, "import gleam/list") |> list.first()
  let user_pos = string.split(code, "import app/types") |> list.first()

  // gleam/list should appear before app/types
  case list_pos, user_pos {
    Ok(before_list), Ok(before_user) ->
      should.be_true(string.length(before_list) < string.length(before_user))
    _, _ -> should.fail()
  }
}

// === If with multiple children in branch needing fragment ===

pub fn generate_imports_if_branch_multiple_children_test() {
  let template =
    Template(imports: [], params: [], body: [
      IfNode(
        condition: "show",
        then_branch: [
          Element("div", [], [], test_span()),
          Element("span", [], [], test_span()),
        ],
        else_branch: [TextNode("No", test_span())],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Multiple children in branch require fragment
  should.be_true(string.contains(code, "fragment"))
}

// === Case with multiple branches requiring fragment ===

pub fn generate_imports_case_multiple_children_test() {
  let template =
    Template(imports: [], params: [], body: [
      CaseNode(
        expr: "result",
        branches: [
          CaseBranch(
            "Ok(x)",
            [
              Element("div", [], [], test_span()),
              Element("span", [], [], test_span()),
            ],
            test_span(),
          ),
          CaseBranch("Error(_)", [TextNode("Error", test_span())], test_span()),
        ],
        span: test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Multiple children in branch require fragment
  should.be_true(string.contains(code, "fragment"))
}

// === Nested if without else requires none ===

pub fn generate_imports_nested_if_no_else_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [],
        [
          IfNode(
            condition: "show",
            then_branch: [TextNode("Yes", test_span())],
            else_branch: [],
            span: test_span(),
          ),
        ],
        test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "abc123")

  // Nested if without else requires none
  should.be_true(string.contains(code, "none"))
}

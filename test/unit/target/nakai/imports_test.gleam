import ghtml/target/nakai
import ghtml/types.{
  type Span, EachNode, Element, EventAttribute, IfNode, Position, Span,
  StaticAttribute, Template, TextNode,
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

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "import nakai/html"))

  // Should NOT have these (not needed)
  should.be_false(string.contains(code, "import gleam/list"))
  should.be_false(string.contains(code, "import nakai/attr"))
  should.be_false(string.contains(code, "lustre"))
}

pub fn generate_imports_with_user_imports_test() {
  let template =
    Template(imports: ["gleam/io", "app/types.{type User}"], params: [], body: [
      Element("div", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

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

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // Has else, so html.Nothing should NOT appear in the generated code body
  // (it uses html.Text("No") instead)
  should.be_true(string.contains(code, "html.Text(\"No\")"))
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

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // No else, so html.Nothing IS used
  should.be_true(string.contains(code, "html.Nothing"))
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

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // Each requires list (but not keyed — Nakai uses Fragment)
  should.be_true(string.contains(code, "import gleam/list"))
  should.be_false(string.contains(code, "keyed"))
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

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // Each with index requires gleam/int
  should.be_true(string.contains(code, "import gleam/int"))
}

pub fn generate_no_event_import_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "button",
        [EventAttribute("click", "on_click", [])],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // No event import for Nakai
  should.be_false(string.contains(code, "event"))
}

pub fn generate_imports_with_attrs_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("button", [StaticAttribute("class", "btn")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "import nakai/attr"))
}

pub fn generate_imports_without_attrs_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("button", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // No attrs, no nakai/attr
  should.be_false(string.contains(code, "import nakai/attr"))
}

pub fn generate_imports_with_fragment_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
      Element("span", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // Multiple roots use html.Fragment
  should.be_true(string.contains(code, "html.Fragment"))
}

pub fn generate_imports_single_root_no_fragment_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_false(string.contains(code, "Fragment"))
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

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "import gleam/list.{map, filter}"))

  // Should NOT have duplicate auto-import
  let list_import_count =
    code
    |> string.split("import gleam/list")
    |> list.length()
  should.equal(list_import_count, 2)
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

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "import gleam/int"))

  let int_import_count =
    code
    |> string.split("import gleam/int")
    |> list.length()
  should.equal(int_import_count, 2)
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

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // Auto imports should come before user imports
  let list_pos = string.split(code, "import gleam/list") |> list.first()
  let user_pos = string.split(code, "import app/types") |> list.first()

  case list_pos, user_pos {
    Ok(before_list), Ok(before_user) ->
      should.be_true(string.length(before_list) < string.length(before_user))
    _, _ -> should.fail()
  }
}

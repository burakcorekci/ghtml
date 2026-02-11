//// Tests for the codegen dispatcher.
////
//// Verifies that codegen.generate() correctly dispatches to the
//// appropriate target module based on the Target type.

import ghtml/codegen
import ghtml/target/lustre
import ghtml/target/nakai
import ghtml/types.{
  type Span, Element, EventAttribute, ExprNode, IfNode, Lustre, Nakai, Position,
  Span, StaticAttribute, Template, TextNode,
}
import gleam/option.{None}
import gleam/string
import gleeunit/should

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === Dispatcher Tests ===

pub fn dispatcher_routes_to_lustre_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [TextNode("Hello", test_span())], test_span()),
    ])

  let via_dispatcher =
    codegen.generate(template, "test.ghtml", "abc123", Lustre)
  let via_direct = lustre.generate(template, "test.ghtml", "abc123")

  // Dispatcher output should be identical to direct target call
  should.equal(via_dispatcher, via_direct)
}

pub fn dispatcher_produces_valid_lustre_output_test() {
  let template =
    Template(imports: ["gleam/io"], params: [#("name", "String")], body: [
      Element(
        "div",
        [StaticAttribute("class", "container")],
        [ExprNode("name", test_span())],
        test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "hash123", Lustre)

  // Should have Lustre-specific output
  should.be_true(string.contains(code, "import lustre/element"))
  should.be_true(string.contains(code, "import lustre/element/html"))
  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "attribute.class(\"container\")"))
  should.be_true(string.contains(code, "text(name)"))
  should.be_true(string.contains(code, "pub fn render(name name: String)"))
}

pub fn dispatcher_with_complex_template_test() {
  let template =
    Template(imports: [], params: [#("show", "Bool")], body: [
      IfNode(
        "show",
        [Element("span", [], [TextNode("Yes", test_span())], test_span())],
        [],
        test_span(),
      ),
    ])

  let via_dispatcher =
    codegen.generate(template, "test.ghtml", "abc123", Lustre)
  let via_direct = lustre.generate(template, "test.ghtml", "abc123")

  should.equal(via_dispatcher, via_direct)
}

pub fn dispatcher_with_events_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "button",
        [EventAttribute("click", "on_click", [])],
        [TextNode("Click me", test_span())],
        test_span(),
      ),
    ])

  let via_dispatcher =
    codegen.generate(template, "test.ghtml", "abc123", Lustre)
  let via_direct = lustre.generate(template, "test.ghtml", "abc123")

  should.equal(via_dispatcher, via_direct)
}

pub fn dispatcher_with_each_test() {
  let template =
    Template(imports: [], params: [#("items", "List(String)")], body: [
      types.EachNode(
        "items",
        "item",
        None,
        [Element("li", [], [ExprNode("item", test_span())], test_span())],
        test_span(),
      ),
    ])

  let via_dispatcher =
    codegen.generate(template, "test.ghtml", "abc123", Lustre)
  let via_direct = lustre.generate(template, "test.ghtml", "abc123")

  should.equal(via_dispatcher, via_direct)
}

// === Nakai Dispatcher Tests ===

pub fn dispatcher_routes_to_nakai_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [TextNode("Hello", test_span())], test_span()),
    ])

  let via_dispatcher = codegen.generate(template, "test.ghtml", "abc123", Nakai)
  let via_direct = nakai.generate(template, "test.ghtml", "abc123")

  should.equal(via_dispatcher, via_direct)
}

pub fn dispatcher_produces_valid_nakai_output_test() {
  let template =
    Template(imports: ["gleam/io"], params: [#("name", "String")], body: [
      Element(
        "div",
        [StaticAttribute("class", "container")],
        [ExprNode("name", test_span())],
        test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.ghtml", "hash123", Nakai)

  should.be_true(string.contains(code, "import nakai/html"))
  should.be_true(string.contains(code, "import nakai/attr"))
  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "attr.class(\"container\")"))
  should.be_true(string.contains(code, "html.Text(name)"))
  should.be_true(string.contains(code, "pub fn render(name name: String)"))
}

pub fn dispatcher_nakai_with_complex_template_test() {
  let template =
    Template(imports: [], params: [#("show", "Bool")], body: [
      IfNode(
        "show",
        [Element("span", [], [TextNode("Yes", test_span())], test_span())],
        [],
        test_span(),
      ),
    ])

  let via_dispatcher = codegen.generate(template, "test.ghtml", "abc123", Nakai)
  let via_direct = nakai.generate(template, "test.ghtml", "abc123")

  should.equal(via_dispatcher, via_direct)
}

pub fn dispatcher_nakai_with_each_test() {
  let template =
    Template(imports: [], params: [#("items", "List(String)")], body: [
      types.EachNode(
        "items",
        "item",
        None,
        [Element("li", [], [ExprNode("item", test_span())], test_span())],
        test_span(),
      ),
    ])

  let via_dispatcher = codegen.generate(template, "test.ghtml", "abc123", Nakai)
  let via_direct = nakai.generate(template, "test.ghtml", "abc123")

  should.equal(via_dispatcher, via_direct)
}

import ghtml/target/lustre
import ghtml/types.{
  type Span, DynamicAttribute, Element, EventAttribute, Position, Span,
  StaticAttribute, Template, TextNode,
}
import gleam/string
import gleeunit/should

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

pub fn generate_component_self_closing_test() {
  let template =
    Template(imports: ["web/app/components/card"], params: [], body: [
      Element("Card", [], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "card.render()"))
  should.be_false(string.contains(code, "html.Card"))
}

pub fn generate_component_with_attrs_test() {
  let template =
    Template(imports: ["web/app/components/kpi_card"], params: [], body: [
      Element(
        "KpiCard",
        [
          StaticAttribute("title", "Contacts"),
          DynamicAttribute("count", "42"),
        ],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "kpi_card.render("))
  should.be_true(string.contains(code, "title: \"Contacts\""))
  should.be_true(string.contains(code, "count: 42"))
}

pub fn generate_component_with_children_test() {
  let template =
    Template(imports: ["web/app/components/card"], params: [], body: [
      Element(
        "Card",
        [],
        [Element("p", [], [TextNode("Hello", test_span())], test_span())],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "card.render(children: ["))
  should.be_true(string.contains(code, "html.p("))
}

pub fn generate_component_event_as_labeled_arg_test() {
  let template =
    Template(imports: ["web/app/components/my_button"], params: [], body: [
      Element(
        "MyButton",
        [EventAttribute("click", "on_submit", [])],
        [TextNode("Submit", test_span())],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "my_button.render(on_click: on_submit"))
}

import ghtml/codegen_utils
import ghtml/target/nakai
import ghtml/types.{
  type Span, DynamicAttribute, Element, Position, Span, StaticAttribute,
  Template, TextNode,
}
import gleam/string
import gleeunit/should

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === pascal_to_snake tests ===

pub fn pascal_to_snake_simple_test() {
  codegen_utils.pascal_to_snake("Card")
  |> should.equal("card")
}

pub fn pascal_to_snake_two_words_test() {
  codegen_utils.pascal_to_snake("KpiCard")
  |> should.equal("kpi_card")
}

pub fn pascal_to_snake_three_words_test() {
  codegen_utils.pascal_to_snake("StyleSheetLoader")
  |> should.equal("style_sheet_loader")
}

pub fn pascal_to_snake_single_char_test() {
  codegen_utils.pascal_to_snake("A")
  |> should.equal("a")
}

pub fn is_component_uppercase_test() {
  codegen_utils.is_component("KpiCard")
  |> should.be_true()
}

pub fn is_component_lowercase_test() {
  codegen_utils.is_component("div")
  |> should.be_false()
}

pub fn is_component_custom_element_test() {
  codegen_utils.is_component("sl-button")
  |> should.be_false()
}

// === Component code generation tests (Nakai) ===

pub fn generate_component_self_closing_test() {
  let template =
    Template(imports: ["web/app/lib/icons"], params: [], body: [
      Element("Icons", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "icons.render()"))
}

pub fn generate_component_with_static_attr_test() {
  let template =
    Template(imports: ["web/app/components/kpi_card"], params: [], body: [
      Element(
        "KpiCard",
        [StaticAttribute("title", "Contacts")],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "kpi_card.render(title: \"Contacts\")"))
}

pub fn generate_component_with_dynamic_attr_test() {
  let template =
    Template(imports: ["web/app/components/kpi_card"], params: [], body: [
      Element(
        "KpiCard",
        [DynamicAttribute("count", "42")],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "kpi_card.render(count: 42)"))
}

pub fn generate_component_with_mixed_attrs_test() {
  let template =
    Template(imports: ["features/ui/kpi_card"], params: [], body: [
      Element(
        "KpiCard",
        [
          StaticAttribute("title", "Contacts"),
          DynamicAttribute("count", "int.to_string(n)"),
          DynamicAttribute("icon", "icons.paperplane()"),
        ],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "kpi_card.render("))
  should.be_true(string.contains(code, "title: \"Contacts\""))
  should.be_true(string.contains(code, "count: int.to_string(n)"))
  should.be_true(string.contains(code, "icon: icons.paperplane()"))
}

pub fn generate_component_with_children_test() {
  let template =
    Template(imports: ["web/app/components/card"], params: [], body: [
      Element(
        "Card",
        [DynamicAttribute("asset_path", "asset_path")],
        [
          Element("h1", [], [TextNode("Title", test_span())], test_span()),
          Element("p", [], [TextNode("Content", test_span())], test_span()),
        ],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "card.render("))
  should.be_true(string.contains(code, "asset_path: asset_path"))
  should.be_true(string.contains(code, "children: ["))
  should.be_true(string.contains(code, "html.h1("))
  should.be_true(string.contains(code, "html.p("))
}

pub fn generate_component_kebab_attr_test() {
  let template =
    Template(imports: ["web/app/components/card"], params: [], body: [
      Element(
        "Card",
        [DynamicAttribute("asset-path", "asset_path")],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "asset_path: asset_path"))
}

pub fn component_does_not_generate_html_element_test() {
  let template =
    Template(imports: ["web/app/components/card"], params: [], body: [
      Element("Card", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // Should NOT generate html.Card or html.Element("Card", ...)
  should.be_false(string.contains(code, "html.Card"))
  should.be_false(string.contains(code, "html.Element(\"Card\""))
  should.be_true(string.contains(code, "card.render()"))
}

pub fn component_no_attr_import_test() {
  // A template with ONLY a component (no regular HTML attrs) should not import nakai/attr
  let template =
    Template(imports: ["web/app/components/card"], params: [], body: [
      Element(
        "Card",
        [StaticAttribute("title", "Hi")],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_false(string.contains(code, "import nakai/attr"))
}

import ghtml/target/nakai
import ghtml/types.{
  type Span, Element, ExprNode, Position, Span, Template, TextNode,
}
import gleam/list
import gleam/string
import gleeunit/should

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === Element Generation Tests ===

pub fn generate_standard_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.div([], [])"))
}

pub fn generate_custom_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("sl-button", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.Element(\"sl-button\""))
}

pub fn generate_void_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("br", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.br("))
}

pub fn generate_nested_elements_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [Element("span", [], [], test_span())], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "html.span("))
}

// === Text Generation Tests ===

pub fn generate_text_node_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [TextNode("Hello, World!", test_span())], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.Text(\"Hello, World!\")"))
}

pub fn generate_text_with_escapes_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [TextNode("Line 1\nLine 2", test_span())], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "\\n"))
}

pub fn generate_text_with_quotes_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [TextNode("Say \"Hello\"", test_span())], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "\\\"Hello\\\""))
}

pub fn generate_whitespace_normalization_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [],
        [TextNode("  multiple   spaces  ", test_span())],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_false(string.contains(code, "multiple   spaces"))
  should.be_true(string.contains(code, "multiple spaces"))
}

// === Expression Generation Tests ===

pub fn generate_expr_node_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [ExprNode("user.name", test_span())], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.Text(user.name)"))
}

pub fn generate_complex_expr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [],
        [ExprNode("int.to_string(count)", test_span())],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.Text(int.to_string(count))"))
}

// === Function Generation Tests ===

pub fn generate_function_signature_test() {
  let template =
    Template(
      imports: [],
      params: [#("name", "String"), #("count", "Int")],
      body: [Element("div", [], [], test_span())],
    )

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "pub fn render("))
  should.be_true(string.contains(code, "name: String"))
  should.be_true(string.contains(code, "count: Int"))
  should.be_true(string.contains(code, ") -> html.Node"))
}

pub fn generate_complex_param_types_test() {
  let template =
    Template(
      imports: [],
      params: [#("items", "List(Item)"), #("handler", "fn(String) -> msg")],
      body: [Element("div", [], [], test_span())],
    )

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "items: List(Item)"))
  should.be_true(string.contains(code, "handler: fn(String) -> msg"))
}

// === Header Generation Tests ===

pub fn generate_header_test() {
  let template = Template(imports: [], params: [], body: [])

  let code = nakai.generate(template, "src/components/card.ghtml", "abc123")

  should.be_true(string.contains(code, "// @generated from card.ghtml"))
  should.be_true(string.contains(code, "// @hash abc123"))
  should.be_true(string.contains(code, "DO NOT EDIT"))
}

// === Multiple Root Elements Test ===

pub fn generate_multiple_roots_fragment_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
      Element("span", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.Fragment("))
}

// === Indentation Tests ===

pub fn generate_proper_indentation_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
      Element("span", [], [], test_span()),
      Element("p", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  let lines = string.split(code, "\n")
  should.be_true(list.any(lines, fn(l) { string.starts_with(l, "    ") }))
}

// === Void Element No Children Test ===

pub fn void_element_ignores_children_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "img",
        [],
        [TextNode("should be ignored", test_span())],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_false(string.contains(code, "should be ignored"))
}

// === Whitespace-only Text Nodes ===

pub fn whitespace_only_text_skipped_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [],
        [
          TextNode("   \n\t  ", test_span()),
          Element("span", [], [], test_span()),
        ],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.span("))
}

// === Empty Body Test ===

pub fn generate_empty_body_test() {
  let template = Template(imports: [], params: [], body: [])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "pub fn render("))
  should.be_true(string.contains(code, "html.Nothing"))
}

// === Nakai-specific: Custom Void Element Uses LeafElement ===

pub fn generate_custom_void_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("my-icon", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // Custom elements with no children should still use Element (not LeafElement)
  // since the parser doesn't mark custom elements as void
  should.be_true(string.contains(code, "html.Element(\"my-icon\""))
}

// === Nakai-specific: Event Attributes Skipped ===

pub fn event_attributes_skipped_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "button",
        [types.EventAttribute("click", "on_click", [])],
        [TextNode("Click me", test_span())],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // Event attributes should be silently skipped for SSR
  should.be_false(string.contains(code, "click"))
  should.be_false(string.contains(code, "on_click"))
  should.be_true(string.contains(code, "html.button("))
}

// === Format Compliance Tests ===

pub fn generate_format_compliant_params_test() {
  let template =
    Template(
      imports: [],
      params: [#("name", "String"), #("count", "Int")],
      body: [Element("div", [], [], test_span())],
    )

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "name name: String, count count: Int) ->"))
}

pub fn generate_format_compliant_single_child_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [TextNode("hello", test_span())], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.div([], [html.Text(\"hello\")])"))
}

pub fn generate_format_compliant_nested_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [],
        [Element("span", [], [TextNode("hi", test_span())], test_span())],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "html.div([], [html.span([], [html.Text(\"hi\")])])",
  ))
}

pub fn generate_trailing_newline_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.ends_with(code, "\n"))
}

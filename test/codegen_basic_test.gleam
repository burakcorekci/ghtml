import gleam/list
import gleam/string
import gleeunit/should
import lustre_template_gen/codegen
import lustre_template_gen/types.{
  type Span, Element, ExprNode, Position, Span, Template, TextNode,
}

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === Element Generation Tests ===

pub fn generate_standard_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div([], [])"))
}

pub fn generate_custom_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("sl-button", [], [], test_span()),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "element(\"sl-button\""))
}

pub fn generate_void_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("br", [], [], test_span()),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.br("))
}

pub fn generate_nested_elements_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [Element("span", [], [], test_span())], test_span()),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "html.span("))
}

// === Text Generation Tests ===

pub fn generate_text_node_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [TextNode("Hello, World!", test_span())], test_span()),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "text(\"Hello, World!\")"))
}

pub fn generate_text_with_escapes_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [TextNode("Line 1\nLine 2", test_span())], test_span()),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "\\n"))
}

pub fn generate_text_with_quotes_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [TextNode("Say \"Hello\"", test_span())], test_span()),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

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

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Whitespace should be collapsed in text content
  // The original "multiple   spaces" should become "multiple spaces"
  should.be_false(string.contains(code, "multiple   spaces"))
  // Should have the normalized version
  should.be_true(string.contains(code, "multiple spaces"))
}

// === Expression Generation Tests ===

pub fn generate_expr_node_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [ExprNode("user.name", test_span())], test_span()),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "text(user.name)"))
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

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "text(int.to_string(count))"))
}

// === Function Generation Tests ===

pub fn generate_function_signature_test() {
  let template =
    Template(
      imports: [],
      params: [#("name", "String"), #("count", "Int")],
      body: [Element("div", [], [], test_span())],
    )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "pub fn render("))
  should.be_true(string.contains(code, "name: String"))
  should.be_true(string.contains(code, "count: Int"))
  should.be_true(string.contains(code, ") -> Element(msg)"))
}

pub fn generate_complex_param_types_test() {
  let template =
    Template(
      imports: [],
      params: [#("items", "List(Item)"), #("handler", "fn(String) -> msg")],
      body: [Element("div", [], [], test_span())],
    )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "items: List(Item)"))
  should.be_true(string.contains(code, "handler: fn(String) -> msg"))
}

// === Header Generation Tests ===

pub fn generate_header_test() {
  let template = Template(imports: [], params: [], body: [])

  let code = codegen.generate(template, "src/components/card.lustre", "abc123")

  should.be_true(string.contains(code, "// @generated from card.lustre"))
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

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Multiple roots should use fragment
  should.be_true(string.contains(code, "fragment("))
}

// === Indentation Tests ===

pub fn generate_proper_indentation_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [],
        [
          Element("span", [], [TextNode("text", test_span())], test_span()),
        ],
        test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Code should be properly indented
  let lines = string.split(code, "\n")
  should.be_true(list.any(lines, fn(l) { string.starts_with(l, "    ") }))
}

// === Void Element No Children Test ===

pub fn void_element_ignores_children_test() {
  // Even if children are provided to a void element, they should be ignored
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "img",
        [],
        [TextNode("should be ignored", test_span())],
        test_span(),
      ),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Void elements shouldn't have children in output
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

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Whitespace-only text nodes should be skipped
  // We should see the span but not a text node with whitespace
  should.be_true(string.contains(code, "html.span("))
}

// === Empty Body Test ===

pub fn generate_empty_body_test() {
  let template = Template(imports: [], params: [], body: [])

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Empty body should generate a valid function with fragment
  should.be_true(string.contains(code, "pub fn render("))
  should.be_true(string.contains(code, "fragment("))
}

// === Import Generation Test ===

pub fn generate_imports_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
    ])

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Should have Lustre imports
  should.be_true(string.contains(code, "import lustre/element"))
}

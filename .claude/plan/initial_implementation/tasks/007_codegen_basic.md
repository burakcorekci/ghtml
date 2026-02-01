# Task 007: Code Generation - Basic Elements

## Description
Implement the basic code generation in `codegen.gleam`. This task covers generating Gleam code for HTML elements, text nodes, and expression nodes. Attributes and control flow are covered in subsequent tasks.

## Dependencies
- Task 002: Types Module
- Task 004: Cache Module (for header generation)

## Success Criteria
1. Standard HTML tags generate `html.tag([], [])` calls
2. Custom elements (with `-`) generate `element("tag", [], [])` calls
3. Text nodes generate `text("content")` calls
4. Expression nodes generate `text(expr)` calls
5. Void elements have no children
6. Whitespace is normalized in text content
7. Generated code compiles with Gleam

## Implementation Steps

### 1. Create codegen module structure
```gleam
import lustre_template_gen/types.{
  Template, Node, Element, TextNode, ExprNode, IfNode, EachNode, CaseNode,
  Attr, StaticAttr, DynamicAttr, EventAttr, BooleanAttr,
}
import lustre_template_gen/cache
import gleam/string
import gleam/list
```

### 2. Implement main generate function
```gleam
pub fn generate(template: Template, source_path: String, hash: String) -> String {
  let filename = extract_filename(source_path)
  let header = cache.generate_header(filename, hash)
  let imports = generate_imports(template)
  let body = generate_function(template)

  header <> "\n" <> imports <> "\n\n" <> body
}
```

### 3. Implement element detection
```gleam
fn is_custom_element(tag: String) -> Bool {
  string.contains(tag, "-")
}

const void_elements = [
  "area", "base", "br", "col", "embed", "hr", "img", "input",
  "link", "meta", "param", "source", "track", "wbr",
]

fn is_void_element(tag: String) -> Bool {
  list.contains(void_elements, tag)
}
```

### 4. Implement node generation
```gleam
fn generate_node(node: Node, indent: Int) -> String {
  case node {
    Element(tag, attrs, children, _) -> generate_element(tag, attrs, children, indent)
    TextNode(content, _) -> generate_text(content, indent)
    ExprNode(expr, _) -> generate_expr(expr, indent)
    // Control flow handled in Task 009
    _ -> "none()"
  }
}
```

### 5. Implement element generation
```gleam
fn generate_element(tag: String, attrs: List(Attr), children: List(Node), indent: Int) -> String {
  let attrs_code = "[]"  // Placeholder, Task 008
  let children_code = case is_void_element(tag) {
    True -> ""
    False -> generate_children(children, indent + 1)
  }

  let ind = make_indent(indent)
  case is_custom_element(tag) {
    True -> ind <> "element(\"" <> tag <> "\", [" <> attrs_code <> "], [" <> children_code <> "])"
    False -> ind <> "html." <> tag <> "([" <> attrs_code <> "], [" <> children_code <> "])"
  }
}
```

### 6. Implement text generation with whitespace normalization
```gleam
fn generate_text(content: String, indent: Int) -> String {
  let normalized = normalize_whitespace(content)
  case is_blank(normalized) {
    True -> ""  // Skip whitespace-only nodes
    False -> make_indent(indent) <> "text(\"" <> escape_string(normalized) <> "\")"
  }
}

fn normalize_whitespace(text: String) -> String {
  // Collapse consecutive whitespace to single space
  ...
}

fn is_blank(text: String) -> Bool {
  string.trim(text) == ""
}
```

### 7. Implement expression generation
```gleam
fn generate_expr(expr: String, indent: Int) -> String {
  make_indent(indent) <> "text(" <> expr <> ")"
}
```

### 8. Implement children generation
```gleam
fn generate_children(children: List(Node), indent: Int) -> String {
  children
  |> list.filter_map(fn(child) {
    let code = generate_node(child, indent)
    case code {
      "" -> Error(Nil)
      _ -> Ok(code)
    }
  })
  |> string.join(",\n")
}
```

### 9. Implement function generation
```gleam
fn generate_function(template: Template) -> String {
  let params = generate_params(template.params)
  let body = generate_children(template.body, 1)

  "pub fn render(" <> params <> ") -> Element(msg) {\n"
  <> case list.length(template.body) {
    1 -> body <> "\n"
    _ -> "  fragment([\n" <> body <> "\n  ])\n"
  }
  <> "}"
}

fn generate_params(params: List(#(String, String))) -> String {
  params
  |> list.map(fn(p) { "\n  " <> p.0 <> ": " <> p.1 <> "," })
  |> string.concat()
}
```

### 10. Helper functions
```gleam
fn make_indent(level: Int) -> String {
  string.repeat("  ", level)
}

fn escape_string(s: String) -> String {
  s
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
  |> string.replace("\n", "\\n")
  |> string.replace("\r", "\\r")
  |> string.replace("\t", "\\t")
}

fn extract_filename(path: String) -> String {
  path
  |> string.split("/")
  |> list.last()
  |> result.unwrap("unknown.lustre")
}
```

## Test Cases

### Test File: `test/codegen_basic_test.gleam`

```gleam
import gleeunit/should
import lustre_template_gen/codegen
import lustre_template_gen/types.{
  Template, Node, Element, TextNode, ExprNode,
  Position, Span, StaticAttr,
}
import gleam/string
import gleam/list

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === Element Generation Tests ===

pub fn generate_standard_element_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div([], [])"))
}

pub fn generate_custom_element_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("sl-button", [], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "element(\"sl-button\""))
}

pub fn generate_void_element_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("br", [], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.br("))
}

pub fn generate_nested_elements_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [
      Element("span", [], [], test_span()),
    ], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "html.span("))
}

// === Text Generation Tests ===

pub fn generate_text_node_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [
      TextNode("Hello, World!", test_span()),
    ], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "text(\"Hello, World!\")"))
}

pub fn generate_text_with_escapes_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [
      TextNode("Line 1\nLine 2", test_span()),
    ], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "\\n"))
}

pub fn generate_text_with_quotes_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [
      TextNode("Say \"Hello\"", test_span()),
    ], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "\\\"Hello\\\""))
}

pub fn generate_whitespace_normalization_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [
      TextNode("  multiple   spaces  ", test_span()),
    ], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Whitespace should be collapsed
  should.be_false(string.contains(code, "   "))
}

// === Expression Generation Tests ===

pub fn generate_expr_node_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [
      ExprNode("user.name", test_span()),
    ], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "text(user.name)"))
}

pub fn generate_complex_expr_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [
      ExprNode("int.to_string(count)", test_span()),
    ], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "text(int.to_string(count))"))
}

// === Function Generation Tests ===

pub fn generate_function_signature_test() {
  let template = Template(
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
  let template = Template(
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
  let template = Template(
    imports: [],
    params: [],
    body: [
      Element("div", [], [], test_span()),
      Element("span", [], [], test_span()),
    ],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Multiple roots should use fragment
  should.be_true(string.contains(code, "fragment("))
}

// === Indentation Tests ===

pub fn generate_proper_indentation_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [
      Element("span", [], [
        TextNode("text", test_span()),
      ], test_span()),
    ], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Code should be properly indented
  let lines = string.split(code, "\n")
  should.be_true(list.any(lines, fn(l) { string.starts_with(l, "    ") }))
}
```

## Verification Checklist
- [x] `gleam build` succeeds
- [x] `gleam test` passes all basic codegen tests
- [x] Standard HTML tags use `html.tag()` format
- [x] Custom elements use `element()` format
- [x] Text is properly escaped
- [x] Whitespace is normalized
- [x] Multiple roots use `fragment()`
- [x] Header includes hash and source filename

## Notes
- This task focuses on basic structure; attributes and control flow come later
- The generated code should be valid Gleam syntax
- Indentation improves readability but isn't strictly necessary
- Consider testing generated code with `gleam build` in integration tests

import ghtml/target/nakai
import ghtml/types.{
  type Span, BooleanAttribute, DynamicAttribute, Element, EventAttribute,
  Position, Span, StaticAttribute, Template,
}
import gleam/string
import gleeunit/should

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === Static Attribute Tests ===

pub fn generate_class_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [StaticAttribute("class", "container")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.class(\"container\")"))
}

pub fn generate_id_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [StaticAttribute("id", "main")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.id(\"main\")"))
}

pub fn generate_href_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("a", [StaticAttribute("href", "/home")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.href(\"/home\")"))
}

pub fn generate_type_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [StaticAttribute("type", "text")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.type_(\"text\")"))
}

pub fn generate_unknown_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [StaticAttribute("data-id", "123")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.Attr(\"data-id\", \"123\")"))
}

pub fn generate_aria_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "button",
        [StaticAttribute("aria-label", "Close")],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.Attr(\"aria-label\", \"Close\")"))
}

pub fn generate_attr_with_quotes_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [StaticAttribute("title", "Say \"Hi\"")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "\\\"Hi\\\""))
}

// === Dynamic Attribute Tests ===

pub fn generate_dynamic_class_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [DynamicAttribute("class", "my_class")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.class(my_class)"))
}

pub fn generate_dynamic_value_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "input",
        [DynamicAttribute("value", "user.email")],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.value(user.email)"))
}

pub fn generate_dynamic_unknown_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [DynamicAttribute("data-value", "some_value")],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.Attr(\"data-value\", some_value)"))
}

// === Event Handler Tests (Nakai skips events) ===

pub fn events_are_skipped_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "button",
        [EventAttribute("click", "on_click()", [])],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_false(string.contains(code, "event"))
  should.be_false(string.contains(code, "on_click"))
}

pub fn events_skipped_but_other_attrs_preserved_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "button",
        [
          StaticAttribute("class", "btn"),
          EventAttribute("click", "on_click", []),
        ],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.class(\"btn\")"))
  should.be_false(string.contains(code, "on_click"))
}

// === Boolean Attribute Tests ===

pub fn generate_disabled_attr_html_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("button", [BooleanAttribute("disabled")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // Nakai boolean attrs take no arguments
  should.be_true(string.contains(code, "attr.disabled()"))
}

pub fn generate_readonly_attr_html_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [BooleanAttribute("readonly")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.readonly()"))
}

pub fn generate_checked_attr_html_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [BooleanAttribute("checked")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.checked()"))
}

pub fn generate_disabled_attr_custom_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("sl-button", [BooleanAttribute("disabled")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.Attr(\"disabled\", \"\")"))
}

pub fn generate_custom_boolean_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [BooleanAttribute("custom-flag")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.Attr(\"custom-flag\", \"\")"))
}

// === Multiple Attributes Tests ===

pub fn generate_multiple_attrs_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "input",
        [
          StaticAttribute("type", "text"),
          StaticAttribute("class", "input"),
          DynamicAttribute("value", "user.name"),
          BooleanAttribute("disabled"),
          EventAttribute("input", "on_input", []),
        ],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.type_(\"text\")"))
  should.be_true(string.contains(code, "attr.class(\"input\")"))
  should.be_true(string.contains(code, "attr.value(user.name)"))
  should.be_true(string.contains(code, "attr.disabled()"))
  // Events should be skipped
  should.be_false(string.contains(code, "on_input"))
}

// === Edge Cases ===

pub fn generate_empty_attrs_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.div([], [])"))
}

pub fn generate_attr_with_special_chars_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [StaticAttribute("class", "a & b < c")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "a & b < c"))
}

// === Additional Known Attribute Tests ===

pub fn generate_src_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "img",
        [StaticAttribute("src", "/images/logo.png")],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.src(\"/images/logo.png\")"))
}

pub fn generate_alt_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("img", [StaticAttribute("alt", "Logo")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.alt(\"Logo\")"))
}

pub fn generate_placeholder_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "input",
        [StaticAttribute("placeholder", "Enter name")],
        [],
        test_span(),
      ),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.placeholder(\"Enter name\")"))
}

pub fn generate_name_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [StaticAttribute("name", "username")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.name(\"username\")"))
}

pub fn generate_for_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("label", [StaticAttribute("for", "email-input")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.for(\"email-input\")"))
}

pub fn generate_target_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("a", [StaticAttribute("target", "_blank")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.target(\"_blank\")"))
}

pub fn generate_action_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("form", [StaticAttribute("action", "/submit")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.action(\"/submit\")"))
}

pub fn generate_method_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("form", [StaticAttribute("method", "POST")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.method(\"POST\")"))
}

// === Boolean Attribute Edge Cases ===

pub fn generate_autofocus_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [BooleanAttribute("autofocus")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.autofocus()"))
}

pub fn generate_selected_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("option", [BooleanAttribute("selected")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attr.selected()"))
}

pub fn generate_hidden_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [BooleanAttribute("hidden")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  // "hidden" is not in the known boolean list, uses fallback
  should.be_true(string.contains(code, "attr.Attr(\"hidden\", \"\")"))
}

// === Import Generation with Attributes ===

pub fn generate_imports_with_attributes_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("button", [StaticAttribute("class", "btn")], [], test_span()),
    ])

  let code = nakai.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "import nakai/attr"))
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

  // Nakai has no event module, and events are skipped
  should.be_false(string.contains(code, "import nakai/event"))
  should.be_false(string.contains(code, "import lustre/event"))
}

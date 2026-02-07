import ghtml/target/lustre
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

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.class(\"container\")"))
}

pub fn generate_id_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [StaticAttribute("id", "main")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.id(\"main\")"))
}

pub fn generate_href_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("a", [StaticAttribute("href", "/home")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.href(\"/home\")"))
}

pub fn generate_type_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [StaticAttribute("type", "text")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  // Note: type_ because type is reserved in Gleam
  should.be_true(string.contains(code, "attribute.type_(\"text\")"))
}

pub fn generate_unknown_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [StaticAttribute("data-id", "123")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "attribute.attribute(\"data-id\", \"123\")",
  ))
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

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "attribute.attribute(\"aria-label\", \"Close\")",
  ))
}

pub fn generate_attr_with_quotes_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [StaticAttribute("title", "Say \"Hi\"")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "\\\"Hi\\\""))
}

// === Dynamic Attribute Tests ===

pub fn generate_dynamic_class_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [DynamicAttribute("class", "my_class")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.class(my_class)"))
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

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.value(user.email)"))
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

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "attribute.attribute(\"data-value\", some_value)",
  ))
}

// === Event Handler Tests ===

pub fn generate_click_handler_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "button",
        [EventAttribute("click", "on_click()", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on_click(on_click())"))
}

pub fn generate_input_handler_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "input",
        [EventAttribute("input", "on_input", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on_input(on_input)"))
}

pub fn generate_submit_handler_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "form",
        [EventAttribute("submit", "handle_submit", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on_submit(handle_submit)"))
}

pub fn generate_custom_event_handler_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "sl-dialog",
        [EventAttribute("sl-hide", "on_hide", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on(\"sl-hide\", on_hide)"))
}

pub fn generate_handler_with_params_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "button",
        [EventAttribute("click", "handle_delete(item.id)", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on_click(handle_delete(item.id))"))
}

// === Boolean Attribute Tests ===

pub fn generate_disabled_attr_html_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("button", [BooleanAttribute("disabled")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.disabled(True)"))
}

pub fn generate_readonly_attr_html_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [BooleanAttribute("readonly")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.readonly(True)"))
}

pub fn generate_checked_attr_html_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [BooleanAttribute("checked")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.checked(True)"))
}

pub fn generate_disabled_attr_custom_element_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("sl-button", [BooleanAttribute("disabled")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "attribute.attribute(\"disabled\", \"\")",
  ))
}

pub fn generate_custom_boolean_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [BooleanAttribute("custom-flag")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "attribute.attribute(\"custom-flag\", \"\")",
  ))
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

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.type_(\"text\")"))
  should.be_true(string.contains(code, "attribute.class(\"input\")"))
  should.be_true(string.contains(code, "attribute.value(user.name)"))
  should.be_true(string.contains(code, "attribute.disabled(True)"))
  should.be_true(string.contains(code, "event.on_input(on_input)"))
}

// === Edge Cases ===

pub fn generate_empty_attrs_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "html.div([], [])"))
}

pub fn generate_attr_with_special_chars_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [StaticAttribute("class", "a & b < c")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  // Should preserve special chars (they're valid in attribute values)
  should.be_true(string.contains(code, "a & b < c"))
}

// === Additional Event Handler Tests ===

pub fn generate_blur_handler_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [EventAttribute("blur", "on_blur", [])], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on_blur(on_blur)"))
}

pub fn generate_focus_handler_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "input",
        [EventAttribute("focus", "on_focus", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on_focus(on_focus)"))
}

pub fn generate_change_handler_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "select",
        [EventAttribute("change", "on_change", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on_change(on_change)"))
}

pub fn generate_mouse_enter_handler_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [EventAttribute("mouseenter", "on_enter", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on_mouse_enter(on_enter)"))
}

pub fn generate_mouse_leave_handler_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [EventAttribute("mouseleave", "on_leave", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on_mouse_leave(on_leave)"))
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

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.src(\"/images/logo.png\")"))
}

pub fn generate_alt_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("img", [StaticAttribute("alt", "Logo")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.alt(\"Logo\")"))
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

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.placeholder(\"Enter name\")"))
}

pub fn generate_name_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [StaticAttribute("name", "username")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.name(\"username\")"))
}

pub fn generate_for_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("label", [StaticAttribute("for", "email-input")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.for(\"email-input\")"))
}

pub fn generate_target_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("a", [StaticAttribute("target", "_blank")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.target(\"_blank\")"))
}

pub fn generate_action_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("form", [StaticAttribute("action", "/submit")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.action(\"/submit\")"))
}

pub fn generate_method_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("form", [StaticAttribute("method", "POST")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.method(\"POST\")"))
}

// === Boolean Attributes Edge Cases ===

pub fn generate_required_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [BooleanAttribute("required")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.required(True)"))
}

pub fn generate_hidden_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("div", [BooleanAttribute("hidden")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.attribute(\"hidden\", \"\")"))
}

pub fn generate_autofocus_attr_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("input", [BooleanAttribute("autofocus")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "attribute.autofocus(True)"))
}

// === Import Generation with Attributes ===

pub fn generate_imports_with_attributes_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element("button", [StaticAttribute("class", "btn")], [], test_span()),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "import lustre/attribute"))
}

// === Event Modifier Tests ===

pub fn generate_prevent_default_modifier_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [EventAttribute("on:dragover", "on_dragover", ["prevent"])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "event.prevent_default(event.on(\"dragover\", on_dragover))",
  ))
}

pub fn generate_stop_propagation_modifier_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [EventAttribute("click", "on_click", ["stop"])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "event.stop_propagation(event.on_click(on_click))",
  ))
}

pub fn generate_prevent_and_stop_modifiers_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [EventAttribute("on:drop", "on_drop(Todo)", ["prevent", "stop"])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "event.stop_propagation(event.prevent_default(event.on(\"drop\", on_drop(Todo))))",
  ))
}

pub fn generate_no_modifiers_unchanged_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "button",
        [EventAttribute("click", "handler", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on_click(handler)"))
  should.be_false(string.contains(code, "prevent_default"))
  should.be_false(string.contains(code, "stop_propagation"))
}

pub fn generate_imports_with_events_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "button",
        [EventAttribute("click", "on_click", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "import lustre/event"))
}

// === Generic Event (on:) with Modifier Tests ===

pub fn generate_generic_event_stop_only_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [EventAttribute("on:click", "handler", ["stop"])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "event.stop_propagation(event.on(\"click\", handler))",
  ))
}

pub fn generate_generic_event_prevent_only_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [EventAttribute("on:submit", "on_submit", ["prevent"])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "event.prevent_default(event.on(\"submit\", on_submit))",
  ))
}

pub fn generate_generic_event_both_modifiers_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "div",
        [EventAttribute("on:dragstart", "on_drag", ["prevent", "stop"])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(
    code,
    "event.stop_propagation(event.prevent_default(event.on(\"dragstart\", on_drag)))",
  ))
}

pub fn generate_generic_event_no_modifiers_test() {
  let template =
    Template(imports: [], params: [], body: [
      Element(
        "sl-dialog",
        [EventAttribute("on:sl-show", "on_show", [])],
        [],
        test_span(),
      ),
    ])

  let code = lustre.generate(template, "test.ghtml", "abc123")

  should.be_true(string.contains(code, "event.on(\"sl-show\", on_show)"))
  should.be_false(string.contains(code, "prevent_default"))
  should.be_false(string.contains(code, "stop_propagation"))
}

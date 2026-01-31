# Task 008: Code Generation - Attributes

## Description
Extend the codegen module to handle all attribute types: static, dynamic, event handlers, and boolean attributes. This includes proper mapping to Lustre attribute functions.

## Dependencies
- Task 007: Code Generation - Basic Elements

## Success Criteria
1. Static attributes generate correct `attribute.x("value")` calls
2. Dynamic attributes generate `attribute.x(expr)` calls
3. Event handlers generate `event.on_x(handler)` calls
4. Boolean attributes generate `attribute.x(True)` for standard HTML
5. Boolean attributes generate `attribute.attribute("x", "")` for custom elements
6. Unknown attributes use `attribute.attribute("name", value)`
7. All attribute edge cases (data-*, aria-*, etc.) work correctly

## Implementation Steps

### 1. Define known attribute mappings
```gleam
const known_attributes = [
  #("class", "attribute.class"),
  #("id", "attribute.id"),
  #("href", "attribute.href"),
  #("src", "attribute.src"),
  #("alt", "attribute.alt"),
  #("type", "attribute.type_"),
  #("value", "attribute.value"),
  #("name", "attribute.name"),
  #("placeholder", "attribute.placeholder"),
  #("disabled", "attribute.disabled"),
  #("readonly", "attribute.readonly"),
  #("checked", "attribute.checked"),
  #("selected", "attribute.selected"),
  #("autofocus", "attribute.autofocus"),
  #("for", "attribute.for"),
  #("role", "attribute.role"),
  #("style", "attribute.style"),
  #("width", "attribute.width"),
  #("height", "attribute.height"),
  #("title", "attribute.title"),
  #("target", "attribute.target"),
  #("rel", "attribute.rel"),
  #("action", "attribute.action"),
  #("method", "attribute.method"),
]

const boolean_attributes = [
  "disabled", "readonly", "checked", "selected", "autofocus", "required",
  "multiple", "hidden", "open", "novalidate",
]
```

### 2. Implement attribute generation
```gleam
fn generate_attrs(attrs: List(Attr), is_custom: Bool) -> String {
  attrs
  |> list.map(fn(attr) { generate_attr(attr, is_custom) })
  |> string.join(", ")
}

fn generate_attr(attr: Attr, is_custom: Bool) -> String {
  case attr {
    StaticAttr(name, value) -> generate_static_attr(name, value)
    DynamicAttr(name, expr) -> generate_dynamic_attr(name, expr)
    EventAttr(event, handler) -> generate_event_attr(event, handler)
    BooleanAttr(name) -> generate_boolean_attr(name, is_custom)
  }
}
```

### 3. Implement static attribute generation
```gleam
fn generate_static_attr(name: String, value: String) -> String {
  case find_attr_function(name) {
    Ok(func) -> func <> "(\"" <> escape_string(value) <> "\")"
    Error(_) -> "attribute.attribute(\"" <> name <> "\", \"" <> escape_string(value) <> "\")"
  }
}

fn find_attr_function(name: String) -> Result(String, Nil) {
  list.find_map(known_attributes, fn(pair) {
    case pair.0 == name {
      True -> Ok(pair.1)
      False -> Error(Nil)
    }
  })
}
```

### 4. Implement dynamic attribute generation
```gleam
fn generate_dynamic_attr(name: String, expr: String) -> String {
  case find_attr_function(name) {
    Ok(func) -> func <> "(" <> expr <> ")"
    Error(_) -> "attribute.attribute(\"" <> name <> "\", " <> expr <> ")"
  }
}
```

### 5. Implement boolean attribute generation
```gleam
fn generate_boolean_attr(name: String, is_custom: Bool) -> String {
  case is_custom {
    True -> "attribute.attribute(\"" <> name <> "\", \"\")"
    False -> {
      case list.contains(boolean_attributes, name) {
        True -> {
          case find_attr_function(name) {
            Ok(func) -> func <> "(True)"
            Error(_) -> "attribute.attribute(\"" <> name <> "\", \"\")"
          }
        }
        False -> "attribute.attribute(\"" <> name <> "\", \"\")"
      }
    }
  }
}
```

### 6. Implement event handler generation
```gleam
fn generate_event_attr(event: String, handler: String) -> String {
  case event {
    "click" -> "event.on_click(" <> handler <> ")"
    "input" -> "event.on_input(" <> handler <> ")"
    "change" -> "event.on_change(" <> handler <> ")"
    "submit" -> "event.on_submit(" <> handler <> ")"
    "blur" -> "event.on_blur(" <> handler <> ")"
    "focus" -> "event.on_focus(" <> handler <> ")"
    "keydown" -> "event.on_keydown(" <> handler <> ")"
    "keyup" -> "event.on_keyup(" <> handler <> ")"
    "keypress" -> "event.on_keypress(" <> handler <> ")"
    "mouseenter" -> "event.on_mouse_enter(" <> handler <> ")"
    "mouseleave" -> "event.on_mouse_leave(" <> handler <> ")"
    "mouseover" -> "event.on_mouse_over(" <> handler <> ")"
    "mouseout" -> "event.on_mouse_out(" <> handler <> ")"
    _ -> "event.on(\"" <> event <> "\", " <> handler <> ")"
  }
}
```

### 7. Update element generation to use attributes
```gleam
fn generate_element(tag: String, attrs: List(Attr), children: List(Node), indent: Int) -> String {
  let is_custom = is_custom_element(tag)
  let attrs_code = generate_attrs(attrs, is_custom)
  let children_code = case is_void_element(tag) {
    True -> ""
    False -> generate_children(children, indent + 1)
  }

  let ind = make_indent(indent)
  case is_custom {
    True -> ind <> "element(\"" <> tag <> "\", [" <> attrs_code <> "], [" <> children_code <> "])"
    False -> ind <> "html." <> tag <> "([" <> attrs_code <> "], [" <> children_code <> "])"
  }
}
```

## Test Cases

### Test File: `test/codegen_attributes_test.gleam`

```gleam
import gleeunit/should
import lustre_template_gen/codegen
import lustre_template_gen/types.{
  Template, Element, StaticAttr, DynamicAttr, EventAttr, BooleanAttr,
  Position, Span,
}
import gleam/string

fn test_span() -> Span {
  Span(start: Position(1, 1), end: Position(1, 1))
}

// === Static Attribute Tests ===

pub fn generate_class_attr_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [StaticAttr("class", "container")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.class(\"container\")"))
}

pub fn generate_id_attr_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [StaticAttr("id", "main")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.id(\"main\")"))
}

pub fn generate_href_attr_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("a", [StaticAttr("href", "/home")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.href(\"/home\")"))
}

pub fn generate_type_attr_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("input", [StaticAttr("type", "text")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Note: type_ because type is reserved in Gleam
  should.be_true(string.contains(code, "attribute.type_(\"text\")"))
}

pub fn generate_unknown_attr_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [StaticAttr("data-id", "123")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.attribute(\"data-id\", \"123\")"))
}

pub fn generate_aria_attr_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("button", [StaticAttr("aria-label", "Close")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.attribute(\"aria-label\", \"Close\")"))
}

pub fn generate_attr_with_quotes_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [StaticAttr("title", "Say \"Hi\"")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "\\\"Hi\\\""))
}

// === Dynamic Attribute Tests ===

pub fn generate_dynamic_class_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [DynamicAttr("class", "my_class")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.class(my_class)"))
}

pub fn generate_dynamic_value_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("input", [DynamicAttr("value", "user.email")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.value(user.email)"))
}

pub fn generate_dynamic_unknown_attr_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [DynamicAttr("data-value", "some_value")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.attribute(\"data-value\", some_value)"))
}

// === Event Handler Tests ===

pub fn generate_click_handler_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("button", [EventAttr("click", "on_click()")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "event.on_click(on_click())"))
}

pub fn generate_input_handler_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("input", [EventAttr("input", "on_input")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "event.on_input(on_input)"))
}

pub fn generate_submit_handler_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("form", [EventAttr("submit", "handle_submit")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "event.on_submit(handle_submit)"))
}

pub fn generate_custom_event_handler_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("sl-dialog", [EventAttr("sl-hide", "on_hide")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "event.on(\"sl-hide\", on_hide)"))
}

pub fn generate_handler_with_params_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("button", [EventAttr("click", "handle_delete(item.id)")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "event.on_click(handle_delete(item.id))"))
}

// === Boolean Attribute Tests ===

pub fn generate_disabled_attr_html_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("button", [BooleanAttr("disabled")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.disabled(True)"))
}

pub fn generate_readonly_attr_html_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("input", [BooleanAttr("readonly")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.readonly(True)"))
}

pub fn generate_checked_attr_html_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("input", [BooleanAttr("checked")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.checked(True)"))
}

pub fn generate_disabled_attr_custom_element_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("sl-button", [BooleanAttr("disabled")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.attribute(\"disabled\", \"\")"))
}

pub fn generate_custom_boolean_attr_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [BooleanAttr("custom-flag")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.attribute(\"custom-flag\", \"\")"))
}

// === Multiple Attributes Tests ===

pub fn generate_multiple_attrs_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("input", [
      StaticAttr("type", "text"),
      StaticAttr("class", "input"),
      DynamicAttr("value", "user.name"),
      BooleanAttr("disabled"),
      EventAttr("input", "on_input"),
    ], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "attribute.type_(\"text\")"))
  should.be_true(string.contains(code, "attribute.class(\"input\")"))
  should.be_true(string.contains(code, "attribute.value(user.name)"))
  should.be_true(string.contains(code, "attribute.disabled(True)"))
  should.be_true(string.contains(code, "event.on_input(on_input)"))
}

// === Edge Cases ===

pub fn generate_empty_attrs_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  should.be_true(string.contains(code, "html.div([], [])"))
}

pub fn generate_attr_with_special_chars_test() {
  let template = Template(
    imports: [],
    params: [],
    body: [Element("div", [StaticAttr("class", "a & b < c")], [], test_span())],
  )

  let code = codegen.generate(template, "test.lustre", "abc123")

  // Should preserve special chars (they're valid in attribute values)
  should.be_true(string.contains(code, "a & b < c"))
}
```

## Verification Checklist
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes all attribute tests
- [ ] Known attributes use dedicated functions
- [ ] Unknown attributes use `attribute.attribute()`
- [ ] Boolean attributes differ between standard/custom elements
- [ ] Event handlers map to correct Lustre events
- [ ] Custom events use `event.on()`
- [ ] Attribute values are properly escaped

## Notes
- The attribute mapping should match Lustre's actual API
- Keep the known attributes list updated with Lustre versions
- Event handler expressions are passed through as-is
- Consider adding validation for invalid attribute combinations

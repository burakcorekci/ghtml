# Task 007: SSR HTML Tests

## Description

Create tests that use Lustre's `element.to_string()` to verify that generated components produce the expected HTML output. These tests import the pre-generated modules from task 006 and verify their rendered output.

## Dependencies

- 005_lustre_dev_dependency - Needs Lustre for `element.to_string()`
- 006_ssr_test_modules - Needs the pre-generated test modules

## Success Criteria

1. `test/e2e/e2e_ssr_test.gleam` exists with SSR verification tests
2. Tests cover all generated modules (basic, attributes, control_flow, events, fragments, custom_elements)
3. Tests verify specific HTML structure, not just that rendering succeeds
4. Tests catch regressions in generated code

## Implementation Steps

### 1. Create SSR Test Module

Create `test/e2e/e2e_ssr_test.gleam`:

```gleam
import gleeunit/should
import gleam/string
import lustre/element

// Import pre-generated test modules
import e2e/generated/basic
import e2e/generated/attributes
import e2e/generated/control_flow
import e2e/generated/events
import e2e/generated/fragments
import e2e/generated/custom_elements

// Also need types for control_flow tests
import e2e/generated/types.{User, Admin, Member, Active}
```

### 2. Add Basic Template Tests

```gleam
pub fn basic_renders_title_test() {
  basic.render(title: "Hello", message: "World")
  |> element.to_string()
  |> string.contains("<h1>Hello</h1>")
  |> should.be_true()
}

pub fn basic_renders_message_test() {
  basic.render(title: "Hello", message: "World")
  |> element.to_string()
  |> string.contains("<p class=\"message\">World</p>")
  |> should.be_true()
}

pub fn basic_renders_container_test() {
  basic.render(title: "Test", message: "Test")
  |> element.to_string()
  |> string.contains("<div class=\"container\">")
  |> should.be_true()
}
```

### 3. Add Attributes Template Tests

```gleam
pub fn attributes_renders_form_test() {
  attributes.render(
    id: "my-form",
    name: "username",
    value: "test",
    is_disabled: True,
    is_checked: True,
  )
  |> element.to_string()
  |> string.contains("<form id=\"my-form\"")
  |> should.be_true()
}

pub fn attributes_renders_disabled_input_test() {
  let html = attributes.render(
    id: "form",
    name: "field",
    value: "val",
    is_disabled: True,
    is_checked: False,
  )
  |> element.to_string()

  html |> string.contains("disabled") |> should.be_true()
  html |> string.contains("type=\"text\"") |> should.be_true()
}

pub fn attributes_renders_checkbox_test() {
  attributes.render(
    id: "form",
    name: "field",
    value: "val",
    is_disabled: False,
    is_checked: True,
  )
  |> element.to_string()
  |> string.contains("type=\"checkbox\"")
  |> should.be_true()
}
```

### 4. Add Control Flow Template Tests

```gleam
pub fn control_flow_if_admin_test() {
  let user = User(
    name: "Admin",
    email: "admin@test.com",
    is_admin: True,
    role: Admin,
  )

  control_flow.render(user: user, items: [], show_details: False)
  |> element.to_string()
  |> string.contains("badge admin")
  |> should.be_true()
}

pub fn control_flow_if_not_admin_test() {
  let user = User(
    name: "User",
    email: "user@test.com",
    is_admin: False,
    role: Member(2024),
  )

  control_flow.render(user: user, items: [], show_details: False)
  |> element.to_string()
  |> string.contains("badge user")
  |> should.be_true()
}

pub fn control_flow_each_items_test() {
  let user = User(
    name: "Test",
    email: "test@test.com",
    is_admin: False,
    role: Member(2024),
  )

  let html = control_flow.render(
    user: user,
    items: ["Apple", "Banana", "Cherry"],
    show_details: False,
  )
  |> element.to_string()

  html |> string.contains("Apple") |> should.be_true()
  html |> string.contains("Banana") |> should.be_true()
  html |> string.contains("Cherry") |> should.be_true()
  html |> string.contains("<li") |> should.be_true()
}

pub fn control_flow_case_admin_test() {
  let user = User(
    name: "Admin",
    email: "admin@test.com",
    is_admin: True,
    role: Admin,
  )

  control_flow.render(user: user, items: [], show_details: False)
  |> element.to_string()
  |> string.contains("Administrator")
  |> should.be_true()
}

pub fn control_flow_case_member_test() {
  let user = User(
    name: "Member",
    email: "member@test.com",
    is_admin: False,
    role: Member(2024),
  )

  control_flow.render(user: user, items: [], show_details: False)
  |> element.to_string()
  |> string.contains("Member since 2024")
  |> should.be_true()
}

pub fn control_flow_show_details_test() {
  let user = User(
    name: "Test User",
    email: "test@example.com",
    is_admin: False,
    role: Member(2024),
  )

  let html = control_flow.render(user: user, items: [], show_details: True)
  |> element.to_string()

  html |> string.contains("Name: Test User") |> should.be_true()
  html |> string.contains("Email: test@example.com") |> should.be_true()
}
```

### 5. Add Events Template Tests

```gleam
pub fn events_renders_form_test() {
  // Events don't affect SSR output, but structure should be correct
  events.render(
    on_click: fn() { Nil },
    on_submit: fn() { Nil },
    on_input: fn(_) { Nil },
    on_change: fn(_) { Nil },
    button_text: "Click Me",
  )
  |> element.to_string()
  |> string.contains("<form class=\"event-form\"")
  |> should.be_true()
}

pub fn events_renders_button_text_test() {
  events.render(
    on_click: fn() { Nil },
    on_submit: fn() { Nil },
    on_input: fn(_) { Nil },
    on_change: fn(_) { Nil },
    button_text: "Custom Button",
  )
  |> element.to_string()
  |> string.contains("Custom Button")
  |> should.be_true()
}

pub fn events_renders_input_test() {
  events.render(
    on_click: fn() { Nil },
    on_submit: fn() { Nil },
    on_input: fn(_) { Nil },
    on_change: fn(_) { Nil },
    button_text: "Click",
  )
  |> element.to_string()
  |> string.contains("<input")
  |> should.be_true()
}
```

### 6. Add Fragment Template Tests

```gleam
pub fn fragments_renders_all_sections_test() {
  let html = fragments.render(items: ["One", "Two"])
  |> element.to_string()

  html |> string.contains("<header") |> should.be_true()
  html |> string.contains("<main") |> should.be_true()
  html |> string.contains("<footer") |> should.be_true()
}

pub fn fragments_renders_items_test() {
  let html = fragments.render(items: ["First", "Second", "Third"])
  |> element.to_string()

  html |> string.contains("First") |> should.be_true()
  html |> string.contains("Second") |> should.be_true()
  html |> string.contains("Third") |> should.be_true()
}
```

### 7. Add Custom Elements Template Tests

```gleam
pub fn custom_elements_renders_hyphenated_tag_test() {
  custom_elements.render(content: "Hello", is_active: True)
  |> element.to_string()
  |> string.contains("<my-component")
  |> should.be_true()
}

pub fn custom_elements_renders_nested_custom_test() {
  custom_elements.render(content: "Content", is_active: False)
  |> element.to_string()
  |> string.contains("<slot-content>")
  |> should.be_true()
}

pub fn custom_elements_renders_data_attribute_test() {
  let html = custom_elements.render(content: "Test", is_active: True)
  |> element.to_string()

  html |> string.contains("data-active=\"true\"") |> should.be_true()
}
```

## Test Cases

All test cases are defined in the implementation steps above. Summary:

1. **Basic tests** - Title, message, container rendering
2. **Attributes tests** - Form, inputs, boolean attributes
3. **Control flow tests** - If/else, each loops, case expressions
4. **Events tests** - Form structure, button text (events don't appear in SSR)
5. **Fragments tests** - Multiple root elements, nested content
6. **Custom elements tests** - Hyphenated tags, nested custom elements

## Verification Checklist

- [ ] All implementation steps completed
- [ ] All test cases pass
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] No regressions in existing functionality
- [ ] Tests verify specific HTML content, not just success
- [ ] All generated modules have corresponding tests

## Notes

- SSR tests are faster than build tests since no compilation is needed
- `element.to_string()` produces HTML that may differ slightly from browser rendering
- Event handlers don't appear in SSR output - test structure instead
- String matching with `string.contains()` is simple and effective
- More specific assertions can use regex if needed
- Types for control_flow tests need to be accessible (may need separate types module)

## Files to Modify

- `test/e2e/e2e_ssr_test.gleam` - Create SSR HTML verification tests
- `test/e2e/generated/types.gleam` - May need types module for test data

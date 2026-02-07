//// SSR HTML Verification Tests
////
//// These tests use Lustre's `element.to_string()` to verify that generated
//// components produce the expected HTML output. Tests import the pre-generated
//// modules and verify their rendered output.

import e2e/lustre/generated/attributes
import e2e/lustre/generated/basic
import e2e/lustre/generated/control_flow
import e2e/lustre/generated/custom_elements
import e2e/lustre/generated/edge_cases
import e2e/lustre/generated/fragments
import e2e/lustre/generated/types.{Active, Inactive, User}
import gleam/string
import gleeunit/should
import lustre/element

// =============================================================================
// Basic Template Tests
// =============================================================================

pub fn basic_renders_greeting_class_test() {
  basic.render("Hello")
  |> element.to_string()
  |> string.contains("<div class=\"greeting\">")
  |> should.be_true()
}

pub fn basic_renders_message_in_paragraph_test() {
  basic.render("World")
  |> element.to_string()
  |> string.contains("<p>World</p>")
  |> should.be_true()
}

pub fn basic_dynamic_message_test() {
  basic.render("Dynamic content here")
  |> element.to_string()
  |> string.contains("Dynamic content here")
  |> should.be_true()
}

pub fn basic_empty_message_test() {
  basic.render("")
  |> element.to_string()
  |> string.contains("<p></p>")
  |> should.be_true()
}

// =============================================================================
// Attributes Template Tests
// =============================================================================

pub fn attributes_renders_form_test() {
  attributes.render("test", True, fn(_) { Nil }, fn() { Nil })
  |> element.to_string()
  |> string.contains("<form class=\"form\"")
  |> should.be_true()
}

pub fn attributes_renders_input_type_test() {
  let html =
    attributes.render("val", False, fn(_) { Nil }, fn() { Nil })
    |> element.to_string()

  html |> string.contains("type=\"text\"") |> should.be_true()
}

pub fn attributes_renders_input_class_test() {
  attributes.render("val", False, fn(_) { Nil }, fn() { Nil })
  |> element.to_string()
  |> string.contains("class=\"input\"")
  |> should.be_true()
}

pub fn attributes_renders_value_test() {
  attributes.render("my-value", False, fn(_) { Nil }, fn() { Nil })
  |> element.to_string()
  |> string.contains("value=\"my-value\"")
  |> should.be_true()
}

pub fn attributes_renders_submit_button_test() {
  let html =
    attributes.render("val", False, fn(_) { Nil }, fn() { Nil })
    |> element.to_string()

  html |> string.contains("<button") |> should.be_true()
  html |> string.contains("type=\"submit\"") |> should.be_true()
  html |> string.contains("Submit") |> should.be_true()
}

// =============================================================================
// Control Flow Template Tests
// =============================================================================

pub fn control_flow_if_admin_badge_test() {
  let user = User(name: "Admin", email: "admin@test.com", is_admin: True)

  control_flow.render(user, [], Active)
  |> element.to_string()
  |> string.contains(">Admin<")
  |> should.be_true()
}

pub fn control_flow_if_not_admin_badge_test() {
  let user = User(name: "Regular", email: "regular@test.com", is_admin: False)

  control_flow.render(user, [], Active)
  |> element.to_string()
  |> string.contains(">User<")
  |> should.be_true()
}

pub fn control_flow_article_container_test() {
  let user = User(name: "Test", email: "test@test.com", is_admin: False)

  control_flow.render(user, [], Active)
  |> element.to_string()
  |> string.contains("<article class=\"user-card\"")
  |> should.be_true()
}

pub fn control_flow_each_single_item_test() {
  let user = User(name: "Test", email: "test@test.com", is_admin: False)

  let html =
    control_flow.render(user, ["Apple"], Active)
    |> element.to_string()

  html |> string.contains("Apple") |> should.be_true()
  html |> string.contains("<li") |> should.be_true()
}

pub fn control_flow_each_multiple_items_test() {
  let user = User(name: "Test", email: "test@test.com", is_admin: False)

  let html =
    control_flow.render(user, ["Apple", "Banana", "Cherry"], Active)
    |> element.to_string()

  html |> string.contains("Apple") |> should.be_true()
  html |> string.contains("Banana") |> should.be_true()
  html |> string.contains("Cherry") |> should.be_true()
}

pub fn control_flow_each_empty_list_test() {
  let user = User(name: "Test", email: "test@test.com", is_admin: False)

  let html =
    control_flow.render(user, [], Active)
    |> element.to_string()

  // Should still render the ul container
  html |> string.contains("<ul") |> should.be_true()
}

pub fn control_flow_each_with_index_test() {
  let user = User(name: "Test", email: "test@test.com", is_admin: False)

  let html =
    control_flow.render(user, ["First", "Second"], Active)
    |> element.to_string()

  // Items should have index numbers
  html |> string.contains("0") |> should.be_true()
  html |> string.contains("1") |> should.be_true()
  html |> string.contains("First") |> should.be_true()
  html |> string.contains("Second") |> should.be_true()
}

pub fn control_flow_case_active_status_test() {
  let user = User(name: "Test", email: "test@test.com", is_admin: False)

  control_flow.render(user, [], Active)
  |> element.to_string()
  |> string.contains("status active")
  |> should.be_true()
}

pub fn control_flow_case_inactive_status_test() {
  let user = User(name: "Test", email: "test@test.com", is_admin: False)

  control_flow.render(user, [], Inactive)
  |> element.to_string()
  |> string.contains("status inactive")
  |> should.be_true()
}

pub fn control_flow_badge_class_test() {
  let user = User(name: "Test", email: "test@test.com", is_admin: True)

  control_flow.render(user, [], Active)
  |> element.to_string()
  |> string.contains("class=\"badge\"")
  |> should.be_true()
}

// =============================================================================
// Custom Elements Template Tests
// =============================================================================

pub fn custom_elements_renders_hyphenated_tag_test() {
  custom_elements.render("Hello", True)
  |> element.to_string()
  |> string.contains("<my-component")
  |> should.be_true()
}

pub fn custom_elements_closing_tag_test() {
  custom_elements.render("Hello", True)
  |> element.to_string()
  |> string.contains("</my-component>")
  |> should.be_true()
}

pub fn custom_elements_class_attribute_test() {
  custom_elements.render("Hello", True)
  |> element.to_string()
  |> string.contains("class=\"custom\"")
  |> should.be_true()
}

pub fn custom_elements_renders_slot_content_test() {
  custom_elements.render("Content", False)
  |> element.to_string()
  |> string.contains("<slot-content>")
  |> should.be_true()
}

pub fn custom_elements_slot_content_closing_test() {
  custom_elements.render("Content", False)
  |> element.to_string()
  |> string.contains("</slot-content>")
  |> should.be_true()
}

pub fn custom_elements_renders_content_text_test() {
  custom_elements.render("My custom content", False)
  |> element.to_string()
  |> string.contains("My custom content")
  |> should.be_true()
}

pub fn custom_elements_status_indicator_when_active_test() {
  custom_elements.render("Test", True)
  |> element.to_string()
  |> string.contains("<status-indicator")
  |> should.be_true()
}

pub fn custom_elements_no_status_indicator_when_inactive_test() {
  let html =
    custom_elements.render("Test", False)
    |> element.to_string()

  // When inactive, status-indicator should not appear
  html |> string.contains("status-indicator") |> should.be_false()
}

pub fn custom_elements_active_attribute_test() {
  // Lustre renders empty-value attributes as boolean attributes (no ="")
  custom_elements.render("Test", True)
  |> element.to_string()
  |> string.contains(" active>")
  |> should.be_true()
}

// =============================================================================
// Fragments Template Tests
// =============================================================================

pub fn fragments_renders_header_test() {
  fragments.render([])
  |> element.to_string()
  |> string.contains("<header")
  |> should.be_true()
}

pub fn fragments_renders_main_test() {
  fragments.render([])
  |> element.to_string()
  |> string.contains("<main")
  |> should.be_true()
}

pub fn fragments_renders_footer_test() {
  fragments.render([])
  |> element.to_string()
  |> string.contains("<footer")
  |> should.be_true()
}

pub fn fragments_header_content_test() {
  fragments.render([])
  |> element.to_string()
  |> string.contains("Header Content")
  |> should.be_true()
}

pub fn fragments_footer_content_test() {
  fragments.render([])
  |> element.to_string()
  |> string.contains("Footer Content")
  |> should.be_true()
}

pub fn fragments_header_class_test() {
  fragments.render([])
  |> element.to_string()
  |> string.contains("class=\"header\"")
  |> should.be_true()
}

pub fn fragments_main_class_test() {
  fragments.render([])
  |> element.to_string()
  |> string.contains("class=\"main\"")
  |> should.be_true()
}

pub fn fragments_footer_class_test() {
  fragments.render([])
  |> element.to_string()
  |> string.contains("class=\"footer\"")
  |> should.be_true()
}

pub fn fragments_renders_items_test() {
  let items = ["First", "Second"]
  let html = fragments.render(items) |> element.to_string()

  html |> string.contains("First") |> should.be_true()
  html |> string.contains("Second") |> should.be_true()
}

pub fn fragments_renders_items_in_paragraphs_test() {
  let items = ["Content"]
  fragments.render(items)
  |> element.to_string()
  // Keyed elements have data-lustre-key attribute, so check for <p with space
  |> string.contains("<p ")
  |> should.be_true()
}

pub fn fragments_empty_items_test() {
  let html = fragments.render([]) |> element.to_string()

  // Should still render header, main, footer even with no items
  html |> string.contains("<header") |> should.be_true()
  html |> string.contains("<main") |> should.be_true()
  html |> string.contains("<footer") |> should.be_true()
}

// =============================================================================
// Edge Cases Template Tests
// =============================================================================

pub fn edge_cases_renders_void_br_test() {
  edge_cases.render()
  |> element.to_string()
  |> string.contains("<br")
  |> should.be_true()
}

pub fn edge_cases_renders_void_input_test() {
  edge_cases.render()
  |> element.to_string()
  |> string.contains("<input")
  |> should.be_true()
}

pub fn edge_cases_input_type_test() {
  edge_cases.render()
  |> element.to_string()
  |> string.contains("type=\"text\"")
  |> should.be_true()
}

pub fn edge_cases_escaped_braces_test() {
  edge_cases.render()
  |> element.to_string()
  |> string.contains("{escaped braces}")
  |> should.be_true()
}

pub fn edge_cases_container_div_test() {
  edge_cases.render()
  |> element.to_string()
  |> string.contains("<div>")
  |> should.be_true()
}

pub fn edge_cases_span_element_test() {
  edge_cases.render()
  |> element.to_string()
  |> string.contains("<span>")
  |> should.be_true()
}

//// Tests for pre-generated SSR test modules.
////
//// Verifies that all generated modules exist, compile, and have proper headers.

import e2e/lustre/generated/basic as basic_template
import e2e/lustre/generated/control_flow as control_flow_template
import e2e/lustre/generated/custom_elements as custom_elements_template
import e2e/lustre/generated/edge_cases as edge_cases_template
import e2e/lustre/generated/fragments as fragments_template
import e2e/lustre/generated/types.{Active, User}
import e2e_helpers
import gleam/list
import gleam/string
import gleeunit/should
import lustre/element
import simplifile

/// List of expected generated module names (matching fixtures)
const expected_modules = [
  "basic", "attributes", "control_flow", "fragments", "custom_elements",
  "edge_cases",
]

pub fn all_generated_modules_exist_test() {
  let generated_dir = e2e_helpers.generated_dir()

  expected_modules
  |> list.each(fn(name) {
    let path = generated_dir <> "/" <> name <> ".gleam"
    let assert Ok(True) = simplifile.is_file(path)
  })
}

pub fn generated_modules_have_headers_test() {
  let generated_dir = e2e_helpers.generated_dir()

  expected_modules
  |> list.each(fn(name) {
    let path = generated_dir <> "/" <> name <> ".gleam"
    let assert Ok(content) = simplifile.read(path)

    // Check for @generated header
    content
    |> string.contains("@generated")
    |> should.be_true()

    // Check for @hash header
    content
    |> string.contains("@hash")
    |> should.be_true()
  })
}

pub fn generated_modules_have_render_function_test() {
  let generated_dir = e2e_helpers.generated_dir()

  expected_modules
  |> list.each(fn(name) {
    let path = generated_dir <> "/" <> name <> ".gleam"
    let assert Ok(content) = simplifile.read(path)

    // Check for pub fn render
    content
    |> string.contains("pub fn render(")
    |> should.be_true()
  })
}

pub fn generated_modules_can_be_imported_test() {
  // This test verifies that modules can be imported and their render functions called
  // The fact that this compiles proves the modules are importable

  // Basic template
  let basic_html = basic_template.render("Hello")
  basic_html
  |> element.to_string()
  |> string.contains("Hello")
  |> should.be_true()

  // Edge cases template (no params)
  let edge_html = edge_cases_template.render()
  edge_html
  |> element.to_string()
  |> string.contains("escaped braces")
  |> should.be_true()
}

pub fn control_flow_template_renders_correctly_test() {
  let user = User(name: "Alice", email: "alice@test.com", is_admin: True)
  let items = ["first", "second"]
  let status = Active

  let html = control_flow_template.render(user, items, status)
  let html_str = element.to_string(html)

  // Should contain admin badge for admin user
  html_str
  |> string.contains("Admin")
  |> should.be_true()

  // Should contain list items
  html_str
  |> string.contains("first")
  |> should.be_true()

  // Should contain active status
  html_str
  |> string.contains("Active")
  |> should.be_true()
}

pub fn custom_elements_template_renders_test() {
  let html = custom_elements_template.render("content text", True)
  let html_str = element.to_string(html)

  // Should contain custom element tag
  html_str
  |> string.contains("my-component")
  |> should.be_true()

  // Should contain content
  html_str
  |> string.contains("content text")
  |> should.be_true()

  // Should contain active indicator when is_active is true
  html_str
  |> string.contains("status-indicator")
  |> should.be_true()
}

pub fn fragments_template_renders_test() {
  let items = ["Item 1", "Item 2"]
  let html = fragments_template.render(items)
  let html_str = element.to_string(html)

  // Should contain header
  html_str
  |> string.contains("Header Content")
  |> should.be_true()

  // Should contain footer
  html_str
  |> string.contains("Footer Content")
  |> should.be_true()

  // Should contain items
  html_str
  |> string.contains("Item 1")
  |> should.be_true()
}

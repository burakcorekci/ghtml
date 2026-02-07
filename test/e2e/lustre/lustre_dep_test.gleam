/// Tests verifying Lustre is available as a dev dependency.
/// These tests ensure the SSR testing capability using lustre/element.to_string().
import gleam/string
import gleeunit/should
import lustre/attribute
import lustre/element
import lustre/element/html

/// Test 1: Verify lustre/element can create text nodes and convert to string
pub fn lustre_element_to_string_test() {
  element.text("Hello, World!")
  |> element.to_string()
  |> should.equal("Hello, World!")
}

/// Test 2: Verify HTML elements can be created and converted to string
pub fn html_element_to_string_test() {
  html.div([], [element.text("Content")])
  |> element.to_string()
  |> should.equal("<div>Content</div>")
}

/// Test 3: Verify attributes work correctly
pub fn html_with_attributes_test() {
  html.div([attribute.class("container")], [element.text("Hello")])
  |> element.to_string()
  |> should.equal("<div class=\"container\">Hello</div>")
}

/// Test 4: Verify nested elements work
pub fn nested_elements_test() {
  html.div([], [
    html.span([], [element.text("Nested")]),
  ])
  |> element.to_string()
  |> should.equal("<div><span>Nested</span></div>")
}

/// Test 5: Verify multiple attributes work
/// Note: Attribute order may vary in Lustre's rendering, so we check each attribute is present
pub fn multiple_attributes_test() {
  let result =
    html.div([attribute.id("main"), attribute.class("wrapper")], [])
    |> element.to_string()

  // Verify both attributes are present (order may vary)
  string.contains(result, "id=\"main\"") |> should.be_true()
  string.contains(result, "class=\"wrapper\"") |> should.be_true()
  string.starts_with(result, "<div ") |> should.be_true()
  string.ends_with(result, "></div>") |> should.be_true()
}

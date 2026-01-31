//// Integration tests that verify the entire pipeline works end-to-end:
//// parsing real templates, generating valid Gleam code.

import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleeunit/should
import lustre_template_gen/cache
import lustre_template_gen/codegen
import lustre_template_gen/parser
import simplifile

// === Helper Functions ===

fn read_fixture(name: String) -> String {
  let path = "test/fixtures/" <> name
  let assert Ok(content) = simplifile.read(path)
  content
}

fn generate_from_fixture(name: String) -> String {
  let content = read_fixture(name)
  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  codegen.generate(template, name, hash)
}

// === Simple Template Tests ===

pub fn basic_template_generates_test() {
  let code = generate_from_fixture("simple/basic.lustre")

  // Verify structure
  should.be_true(string.contains(code, "// @generated from"))
  should.be_true(string.contains(code, "pub fn render("))
  should.be_true(string.contains(code, "message: String"))
  should.be_true(string.contains(code, "html.div("))
  should.be_true(string.contains(code, "html.p("))
  should.be_true(string.contains(code, "text(message)"))
}

pub fn basic_template_imports_test() {
  let code = generate_from_fixture("simple/basic.lustre")

  // Verify required imports
  should.be_true(string.contains(code, "import lustre/element"))
  should.be_true(string.contains(code, "import lustre/element/html"))
  should.be_true(string.contains(code, "import lustre/attribute"))

  // Should NOT have unused imports
  should.be_false(string.contains(code, "import lustre/event"))
  should.be_false(string.contains(code, "import gleam/list"))
}

// === Attribute Tests ===

pub fn all_attributes_generate_test() {
  let code = generate_from_fixture("attributes/all_attrs.lustre")

  // Static attributes
  should.be_true(string.contains(code, "attribute.type_(\"text\")"))
  should.be_true(string.contains(code, "attribute.class(\"input\")"))
  should.be_true(string.contains(code, "attribute.class(\"form\")"))

  // Dynamic attribute
  should.be_true(string.contains(code, "attribute.value(value)"))

  // Boolean attribute
  should.be_true(string.contains(code, "attribute.disabled(True)"))

  // Event handlers
  should.be_true(string.contains(code, "event.on_input(on_change)"))
  should.be_true(string.contains(code, "event.on_click(on_click())"))

  // Should import event module
  should.be_true(string.contains(code, "import lustre/event"))
}

// === Control Flow Tests ===

pub fn if_else_generates_test() {
  let code = generate_from_fixture("control_flow/full.lustre")

  // Should generate case expression for if
  should.be_true(string.contains(code, "case user.is_admin {"))
  should.be_true(string.contains(code, "True ->"))
  should.be_true(string.contains(code, "False ->"))
}

pub fn each_loop_generates_test() {
  let code = generate_from_fixture("control_flow/full.lustre")

  // Should use keyed and list
  should.be_true(string.contains(code, "keyed("))
  should.be_true(string.contains(code, "list.index_map(items"))

  // Should import list
  should.be_true(string.contains(code, "import gleam/list"))
}

pub fn case_match_generates_test() {
  let code = generate_from_fixture("control_flow/full.lustre")

  // Should generate case expression
  should.be_true(string.contains(code, "case status {"))
  should.be_true(string.contains(code, "Active ->"))
  should.be_true(string.contains(code, "Inactive ->"))
}

// === User Import Tests ===

pub fn user_imports_included_test() {
  let code = generate_from_fixture("control_flow/full.lustre")

  // User imports should be present
  should.be_true(string.contains(code, "import gleam/int"))
  should.be_true(string.contains(
    code,
    "import app/types.{type User, type Status, Active, Inactive}",
  ))
}

// === Error Handling Tests ===

pub fn unclosed_tag_error_test() {
  let content = "<div><span></div>"
  let result = parser.parse(content)

  case result {
    Error(errors) -> {
      should.be_true(errors != [])
    }
    Ok(_) -> should.fail()
  }
}

pub fn unclosed_expression_error_test() {
  let content = "<div>{unclosed</div>"
  let result = parser.parse(content)

  case result {
    Error(errors) -> {
      should.be_true(errors != [])
    }
    Ok(_) -> should.fail()
  }
}

pub fn unclosed_if_error_test() {
  let content = "{#if show}<div></div>"
  let result = parser.parse(content)

  case result {
    Error(errors) -> {
      should.be_true(errors != [])
    }
    Ok(_) -> should.fail()
  }
}

// === Full Example Test ===

pub fn full_example_from_plan_test() {
  // This is the complete example from PLAN.md
  let content =
    "@import(app/models.{type User, type Role, Admin, Member})
@import(app/models.{type Post})
@import(gleam/option.{type Option, Some, None})
@import(gleam/int)

@params(
  user: User,
  posts: List(Post),
  show_email: Bool,
  on_save: fn() -> msg,
  on_email_change: fn(String) -> msg,
)

<article class=\"user-card\">
  <h1>{user.name}</h1>

  {#case user.role}
    {:Admin}
      <sl-badge variant=\"primary\">Admin</sl-badge>
    {:Member(since)}
      <sl-badge variant=\"neutral\">Member since {int.to_string(since)}</sl-badge>
  {/case}

  {#if show_email}
    <sl-input type=\"email\" value={user.email} @input={on_email_change} readonly></sl-input>
  {/if}

  <ul class=\"posts\">
    {#each posts as post, i}
      <li class={row_class(i)}>{post.title}</li>
    {/each}
  </ul>

  <sl-button variant=\"primary\" @click={on_save()}>
    <sl-icon slot=\"prefix\" name=\"save\"></sl-icon>
    Save Changes
  </sl-button>
</article>"

  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, "user_card.lustre", hash)

  // Verify all major features
  should.be_true(string.contains(code, "// @generated from user_card.lustre"))
  should.be_true(string.contains(code, "pub fn render("))

  // Params
  should.be_true(string.contains(code, "user: User"))
  should.be_true(string.contains(code, "posts: List(Post)"))
  should.be_true(string.contains(code, "show_email: Bool"))
  should.be_true(string.contains(code, "on_save: fn() -> msg"))
  should.be_true(string.contains(code, "on_email_change: fn(String) -> msg"))

  // Imports
  should.be_true(string.contains(
    code,
    "import app/models.{type User, type Role, Admin, Member}",
  ))
  should.be_true(string.contains(code, "import gleam/int"))
  should.be_true(string.contains(code, "import gleam/list"))
  should.be_true(string.contains(code, "import lustre/event"))

  // Elements
  should.be_true(string.contains(code, "html.article("))
  should.be_true(string.contains(code, "html.h1("))
  should.be_true(string.contains(code, "html.ul("))
  should.be_true(string.contains(code, "html.li("))

  // Custom elements
  should.be_true(string.contains(code, "element(\"sl-badge\""))
  should.be_true(string.contains(code, "element(\"sl-input\""))
  should.be_true(string.contains(code, "element(\"sl-button\""))
  should.be_true(string.contains(code, "element(\"sl-icon\""))

  // Control flow
  should.be_true(string.contains(code, "case user.role {"))
  should.be_true(string.contains(code, "Admin ->"))
  should.be_true(string.contains(code, "Member(since) ->"))
  should.be_true(string.contains(code, "case show_email {"))
  should.be_true(string.contains(code, "keyed("))

  // Events
  should.be_true(string.contains(code, "event.on_input(on_email_change)"))
  should.be_true(string.contains(code, "event.on_click(on_save())"))
}

// === Performance Test ===

pub fn large_template_performance_test() {
  // Generate a template with many elements
  let items =
    list.range(1, 100)
    |> list.map(fn(i) { "<li>" <> int.to_string(i) <> "</li>" })
    |> string.join("\n")

  let content = "@params()\n\n<ul>\n" <> items <> "\n</ul>"

  // Should parse and generate quickly
  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let _code = codegen.generate(template, "large.lustre", hash)

  // If we get here without timeout, performance is acceptable
  should.be_true(True)
}

// === Hash Verification Test ===

pub fn generated_code_has_correct_hash_test() {
  let content = read_fixture("simple/basic.lustre")
  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, "basic.lustre", hash)

  // Verify the hash in the generated code matches the source hash
  let assert Ok(extracted_hash) = cache.extract_hash(code)
  should.equal(extracted_hash, hash)
}

// === Multiple Roots Test ===

pub fn multiple_roots_uses_fragment_test() {
  let content =
    "@params()

<div>First</div>
<div>Second</div>"

  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, "multi.lustre", hash)

  // Multiple root elements should use fragment
  should.be_true(string.contains(code, "fragment("))
}

// === Empty Params Test ===

pub fn empty_params_test() {
  let content =
    "@params()

<div>No params</div>"

  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, "empty.lustre", hash)

  // Should generate valid function with no parameters
  should.be_true(string.contains(code, "pub fn render() -> Element(msg)"))
}

// === Nested Control Flow Test ===

pub fn nested_control_flow_test() {
  let content =
    "@params(show: Bool, items: List(String))

{#if show}
  {#each items as item}
    <span>{item}</span>
  {/each}
{/if}"

  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, "nested.lustre", hash)

  // Should have both if and each constructs
  should.be_true(string.contains(code, "case show {"))
  should.be_true(string.contains(code, "keyed("))
}

// === Self-closing Tags Test ===

pub fn self_closing_tags_test() {
  let content =
    "@params()

<div>
  <br/>
  <input type=\"text\"/>
  <img src=\"test.png\" alt=\"test\"/>
</div>"

  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, "self_closing.lustre", hash)

  // Should generate valid code for self-closing tags
  should.be_true(string.contains(code, "html.br("))
  should.be_true(string.contains(code, "html.input("))
  should.be_true(string.contains(code, "html.img("))
}

// === HTML Comment Test ===

pub fn html_comments_ignored_test() {
  let content =
    "@params()

<div>
  <!-- This comment should be ignored -->
  <span>visible</span>
</div>"

  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, "comments.lustre", hash)

  // Comment content should not appear in generated code
  should.be_false(string.contains(code, "This comment should be ignored"))
  should.be_true(string.contains(code, "text(\"visible\")"))
}

// === Escaped Braces Test ===

pub fn escaped_braces_test() {
  let content =
    "@params()

<div>Use {{braces}} for templates</div>"

  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, "escaped.lustre", hash)

  // Escaped braces should become literal braces in output
  should.be_true(string.contains(code, "{braces}"))
}

// === Event Handler Variations Test ===

pub fn event_handler_variations_test() {
  let content =
    "@params(
  on_click: fn() -> msg,
  on_input: fn(String) -> msg,
  on_submit: fn() -> msg,
)

<form @submit={on_submit()}>
  <input @input={on_input} @blur={on_input}/>
  <button @click={on_click()}>Click</button>
</form>"

  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = codegen.generate(template, "events.lustre", hash)

  // Various event handlers should be generated correctly
  should.be_true(string.contains(code, "event.on_submit(on_submit())"))
  should.be_true(string.contains(code, "event.on_input(on_input)"))
  should.be_true(string.contains(code, "event.on_blur(on_input)"))
  should.be_true(string.contains(code, "event.on_click(on_click())"))
}

// === Fixture Enhancement Tests ===
// These tests verify the enhanced fixtures parse and generate correctly

pub fn fragments_fixture_test() {
  let code = generate_from_fixture("fragments/multiple_roots.lustre")

  // Should use fragment for multiple root elements
  should.be_true(string.contains(code, "fragment("))

  // Should have all three root elements
  should.be_true(string.contains(code, "html.header("))
  should.be_true(string.contains(code, "html.main("))
  should.be_true(string.contains(code, "html.footer("))

  // Should have each loop
  should.be_true(string.contains(code, "keyed("))
}

pub fn custom_elements_fixture_test() {
  let code = generate_from_fixture("custom_elements/web_components.lustre")

  // Custom elements should use element() function
  should.be_true(string.contains(code, "element(\"my-component\""))
  should.be_true(string.contains(code, "element(\"slot-content\""))
  should.be_true(string.contains(code, "element(\"status-indicator\""))

  // Should have conditional rendering
  should.be_true(string.contains(code, "case is_active {"))
}

pub fn edge_cases_fixture_test() {
  let code = generate_from_fixture("edge_cases/special.lustre")

  // Self-closing tags should work
  should.be_true(string.contains(code, "html.br("))
  should.be_true(string.contains(code, "html.input("))

  // Escaped braces should become literal braces
  should.be_true(string.contains(code, "{escaped braces}"))

  // Comments should be stripped
  should.be_false(string.contains(code, "HTML comment"))
}

pub fn all_fixtures_parse_successfully_test() {
  // Get all fixture files
  let assert Ok(files) = simplifile.get_files("test/fixtures")

  // Filter to .lustre files
  let lustre_files =
    files
    |> list.filter(fn(f) { string.ends_with(f, ".lustre") })

  // Ensure we have fixtures
  should.be_true(lustre_files != [])

  // All fixtures should parse
  lustre_files
  |> list.each(fn(path) {
    let assert Ok(content) = simplifile.read(path)
    let result = parser.parse(content)
    case result {
      Ok(_) -> Nil
      Error(errors) -> {
        // Print which file failed
        io.println("Failed to parse: " <> path)
        errors
        |> list.each(fn(err) { io.println(parser.format_error(err, content)) })
        should.fail()
      }
    }
  })
}

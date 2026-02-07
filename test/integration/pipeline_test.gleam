//// Integration tests for the template generation pipeline.
////
//// These tests focus on:
//// - Error handling for malformed templates
//// - Edge cases (empty params, fragments, nested control flow, comments, etc.)
//// - Cache hash verification
//// - Performance with large templates
////
//// Full compilation and rendering verification is handled by E2E tests
//// in test/e2e/. Those tests prove generated code actually works;
//// these tests verify the pipeline handles edge cases correctly.

import ghtml/cache
import ghtml/parser
import ghtml/target/lustre
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleeunit/should
import simplifile

// === Helper Functions ===

fn generate_from_content(content: String, name: String) -> String {
  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  lustre.generate(template, name, hash)
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

// === Edge Case Tests ===

pub fn empty_params_test() {
  let content =
    "@params()

<div>No params</div>"

  let code = generate_from_content(content, "empty.ghtml")

  // Should generate valid function with no parameters
  should.be_true(string.contains(code, "pub fn render() -> Element(msg)"))
}

pub fn multiple_roots_uses_fragment_test() {
  let content =
    "@params()

<div>First</div>
<div>Second</div>"

  let code = generate_from_content(content, "multi.ghtml")

  // Multiple root elements should use fragment
  should.be_true(string.contains(code, "fragment("))
}

pub fn nested_control_flow_test() {
  let content =
    "@params(show: Bool, items: List(String))

{#if show}
  {#each items as item}
    <span>{item}</span>
  {/each}
{/if}"

  let code = generate_from_content(content, "nested.ghtml")

  // Should have both if and each constructs
  should.be_true(string.contains(code, "case show {"))
  should.be_true(string.contains(code, "keyed.fragment("))
}

pub fn self_closing_tags_test() {
  let content =
    "@params()

<div>
  <br/>
  <input type=\"text\"/>
  <img src=\"test.png\" alt=\"test\"/>
</div>"

  let code = generate_from_content(content, "self_closing.ghtml")

  // Should generate valid code for self-closing tags
  should.be_true(string.contains(code, "html.br("))
  should.be_true(string.contains(code, "html.input("))
  should.be_true(string.contains(code, "html.img("))
}

pub fn html_comments_ignored_test() {
  let content =
    "@params()

<div>
  <!-- This comment should be ignored -->
  <span>visible</span>
</div>"

  let code = generate_from_content(content, "comments.ghtml")

  // Comment content should not appear in generated code
  should.be_false(string.contains(code, "This comment should be ignored"))
  should.be_true(string.contains(code, "text(\"visible\")"))
}

pub fn escaped_braces_test() {
  let content =
    "@params()

<div>Use {{braces}} for templates</div>"

  let code = generate_from_content(content, "escaped.ghtml")

  // Escaped braces should become literal braces in output
  should.be_true(string.contains(code, "{braces}"))
}

// === Cache Integration Tests ===

pub fn generated_code_has_correct_hash_test() {
  let assert Ok(content) = simplifile.read("test/fixtures/simple/basic.ghtml")
  let hash = cache.hash_content(content)
  let assert Ok(template) = parser.parse(content)
  let code = lustre.generate(template, "basic.ghtml", hash)

  // Verify the hash in the generated code matches the source hash
  let assert Ok(extracted_hash) = cache.extract_hash(code)
  should.equal(extracted_hash, hash)
}

// === Performance Tests ===

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
  let _code = lustre.generate(template, "large.ghtml", hash)

  // If we get here without timeout, performance is acceptable
  should.be_true(True)
}

// === Documentation Tests ===

pub fn full_example_from_plan_test() {
  // This is the complete example from PLAN.md - serves as living documentation
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
  let code = lustre.generate(template, "user_card.ghtml", hash)

  // Verify all major features
  should.be_true(string.contains(code, "// @generated from user_card.ghtml"))
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
  should.be_true(string.contains(code, "keyed.fragment("))

  // Events
  should.be_true(string.contains(code, "event.on_input(on_email_change)"))
  should.be_true(string.contains(code, "event.on_click(on_save())"))
}

// === Fixture Parsing Sanity Check ===

pub fn all_fixtures_parse_successfully_test() {
  // Get all fixture files
  let assert Ok(files) = simplifile.get_files("test/fixtures")

  // Filter to .ghtml files
  let ghtml_files =
    files
    |> list.filter(fn(f) { string.ends_with(f, ".ghtml") })

  // Ensure we have fixtures
  should.be_true(ghtml_files != [])

  // All fixtures should parse
  ghtml_files
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

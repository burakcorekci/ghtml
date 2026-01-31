# Task 014: Integration Testing

## Description
Create comprehensive integration tests that verify the entire pipeline works end-to-end: parsing real templates, generating valid Gleam code, and ensuring the generated code compiles with the Gleam compiler.

## Dependencies
- Task 011: CLI - Basic Generation
- Task 012: Orphan Cleanup
- Task 013: Watch Mode

## Success Criteria
1. Full template examples from the plan compile successfully
2. Generated code imports are valid
3. Generated code works with Lustre framework
4. Edge cases and error conditions are tested
5. Performance is acceptable for reasonable project sizes
6. CI/CD integration test script is provided

## Implementation Steps

### 1. Create test fixture directory structure
```
test/
  fixtures/
    simple/
      basic.lustre
      expected.gleam
    attributes/
      all_attrs.lustre
      expected.gleam
    control_flow/
      if_else.lustre
      each_loop.lustre
      case_match.lustre
    complex/
      full_example.lustre
      expected.gleam
    errors/
      unclosed_tag.lustre
      invalid_expr.lustre
```

### 2. Create test fixtures

**test/fixtures/simple/basic.lustre:**
```html
@params(message: String)

<div class="greeting">
  <p>{message}</p>
</div>
```

**test/fixtures/attributes/all_attrs.lustre:**
```html
@params(
  value: String,
  is_disabled: Bool,
  on_change: fn(String) -> msg,
  on_click: fn() -> msg,
)

<form class="form">
  <input
    type="text"
    class="input"
    value={value}
    disabled
    @input={on_change}
  />
  <button type="submit" @click={on_click()}>
    Submit
  </button>
</form>
```

**test/fixtures/control_flow/full.lustre:**
```html
@import(gleam/int)
@import(app/types.{type User, type Status, Active, Inactive})

@params(
  user: User,
  items: List(String),
  status: Status,
)

<article class="user-card">
  {#if user.is_admin}
    <span class="badge">Admin</span>
  {:else}
    <span class="badge">User</span>
  {/if}

  <ul>
    {#each items as item, i}
      <li>{int.to_string(i)}: {item}</li>
    {/each}
  </ul>

  {#case status}
    {:Active}
      <span class="status active">Active</span>
    {:Inactive}
      <span class="status inactive">Inactive</span>
  {/case}
</article>
```

### 3. Create integration test file

**test/integration_test.gleam:**
```gleam
import gleeunit/should
import lustre_template_gen/parser
import lustre_template_gen/codegen
import lustre_template_gen/cache
import simplifile
import gleam/string
import gleam/list
import gleam/result

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

fn verify_compiles(code: String) -> Result(Nil, String) {
  // Write to temp file and try to compile
  // This is a simplified check - full compilation would require gleam CLI
  case string.contains(code, "pub fn render(") {
    True -> Ok(Nil)
    False -> Error("Missing render function")
  }
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
  should.be_true(string.contains(code, "import app/types.{type User, type Status, Active, Inactive}"))
}

// === Error Handling Tests ===

pub fn unclosed_tag_error_test() {
  let content = "<div><span></div>"
  let result = parser.parse(content)

  case result {
    Error(errors) -> {
      should.be_true(list.length(errors) > 0)
    }
    Ok(_) -> should.fail()
  }
}

pub fn unclosed_expression_error_test() {
  let content = "<div>{unclosed</div>"
  let result = parser.parse(content)

  case result {
    Error(errors) -> {
      should.be_true(list.length(errors) > 0)
    }
    Ok(_) -> should.fail()
  }
}

pub fn unclosed_if_error_test() {
  let content = "{#if show}<div></div>"
  let result = parser.parse(content)

  case result {
    Error(errors) -> {
      should.be_true(list.length(errors) > 0)
    }
    Ok(_) -> should.fail()
  }
}

// === Full Example Test ===

pub fn full_example_from_plan_test() {
  // This is the complete example from PLAN.md
  let content = "@import(app/models.{type User, type Role, Admin, Member})
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
  should.be_true(string.contains(code, "import app/models.{type User, type Role, Admin, Member}"))
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
  let items = list.range(1, 100)
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
```

### 4. Create CI test script

**.github/workflows/test.yml** (or equivalent):
```yaml
name: Test

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Gleam
        uses: erlef/setup-beam@v1
        with:
          gleam-version: "1.0"
          otp-version: "26"

      - name: Download dependencies
        run: gleam deps download

      - name: Run tests
        run: gleam test

      - name: Build
        run: gleam build

      - name: Integration test
        run: |
          # Create test project
          mkdir -p .test-project/src
          cd .test-project

          # Create gleam.toml
          cat > gleam.toml << 'EOF'
          name = "test_project"
          version = "0.1.0"
          target = "erlang"
          [dependencies]
          gleam_stdlib = ">= 0.34.0"
          EOF

          # Create test template
          cat > src/test.lustre << 'EOF'
          @params(name: String)
          <div>{name}</div>
          EOF

          # Run generator
          cd ..
          gleam run -m lustre_template_gen -- .test-project

          # Verify output
          test -f .test-project/src/test.gleam
          grep -q "@generated" .test-project/src/test.gleam
          grep -q "pub fn render" .test-project/src/test.gleam

          # Cleanup
          rm -rf .test-project
```

## Test Cases

See the comprehensive test file above in section 3.

## Verification Checklist
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes all integration tests
- [ ] Full example from plan generates correctly
- [ ] All control flow constructs work
- [ ] All attribute types work
- [ ] Error messages are helpful
- [ ] Performance is acceptable
- [ ] CI pipeline passes

## Notes
- Integration tests are slower than unit tests
- Consider using test fixtures for complex templates
- The full compilation test requires Lustre to be available
- Performance tests should have reasonable timeout limits
- CI should run on every PR

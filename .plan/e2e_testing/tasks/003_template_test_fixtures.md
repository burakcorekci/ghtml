# Task 003: Template Test Fixtures

## Description

Create `.lustre` template fixtures that comprehensively cover all syntax features supported by the template generator. These fixtures will be used by build verification tests (task 004) and SSR tests (task 007) to ensure generated code works correctly.

## Dependencies

- 001_e2e_infrastructure - Needs fixture directory structure

## Success Criteria

1. Template fixtures exist at `test/e2e/fixtures/templates/`
2. Fixtures cover: basic elements, attributes, control flow, events
3. All fixtures use types from the project template's `types.gleam`
4. Fixtures are valid `.lustre` syntax that parses without errors

## Implementation Steps

### 1. Create Basic Template

Create `test/e2e/fixtures/templates/basic.lustre`:

```html
@params(
  title: String,
  message: String,
)

<div class="container">
  <h1>{title}</h1>
  <p class="message">{message}</p>
</div>
```

This tests:
- Basic element nesting
- Static attributes (class)
- Text interpolation
- Multiple parameters

### 2. Create Attributes Template

Create `test/e2e/fixtures/templates/attributes.lustre`:

```html
@params(
  id: String,
  name: String,
  value: String,
  is_disabled: Bool,
  is_checked: Bool,
)

<form id={id} class="form">
  <input
    type="text"
    name={name}
    value={value}
    disabled
    class="input"
  />
  <input
    type="checkbox"
    checked
  />
  <button type="submit" class="btn">
    Submit
  </button>
</form>
```

This tests:
- Dynamic attributes (id, name, value)
- Static attributes (type, class)
- Boolean attributes (disabled, checked)
- Self-closing elements
- Form elements

### 3. Create Control Flow Template

Create `test/e2e/fixtures/templates/control_flow.lustre`:

```html
@import(gleam/int)
@import(types.{type User, type Role, Admin, Member, Guest})

@params(
  user: User,
  items: List(String),
  show_details: Bool,
)

<article class="user-card">
  {#if user.is_admin}
    <span class="badge admin">Admin</span>
  {:else}
    <span class="badge user">User</span>
  {/if}

  {#if show_details}
    <div class="details">
      <p>Name: {user.name}</p>
      <p>Email: {user.email}</p>
    </div>
  {/if}

  <ul class="items">
    {#each items as item, index}
      <li data-index={int.to_string(index)}>{item}</li>
    {/each}
  </ul>

  {#case user.role}
    {:Admin}
      <span class="role">Administrator</span>
    {:Member(since)}
      <span class="role">Member since {int.to_string(since)}</span>
    {:Guest}
      <span class="role">Guest</span>
  {/case}
</article>
```

This tests:
- Import statements
- Type imports with variants
- If/else blocks
- If without else
- Each loops with index
- Case expressions with pattern matching
- Nested expressions

### 4. Create Events Template

Create `test/e2e/fixtures/templates/events.lustre`:

```html
@params(
  on_click: fn() -> msg,
  on_submit: fn() -> msg,
  on_input: fn(String) -> msg,
  on_change: fn(String) -> msg,
  button_text: String,
)

<form class="event-form" @submit={on_submit()}>
  <input
    type="text"
    class="text-input"
    @input={on_input}
    @change={on_change}
  />
  <button type="button" @click={on_click()}>
    {button_text}
  </button>
  <button type="submit">
    Submit Form
  </button>
</form>
```

This tests:
- Event handlers (@click, @submit, @input, @change)
- Event handlers with and without arguments
- Multiple events on same element
- Form submission events

### 5. Create Fragments Template

Create `test/e2e/fixtures/templates/fragments.lustre`:

```html
@params(
  items: List(String),
)

<>
  <header class="header">Header Content</header>
  <main class="main">
    {#each items as item}
      <p>{item}</p>
    {/each}
  </main>
  <footer class="footer">Footer Content</footer>
</>
```

This tests:
- Fragment syntax (<> </>)
- Multiple root elements
- Fragments with control flow

### 6. Create Custom Elements Template

Create `test/e2e/fixtures/templates/custom_elements.lustre`:

```html
@params(
  content: String,
  is_active: Bool,
)

<my-component class="custom" data-active={if is_active { "true" } else { "false" }}>
  <slot-content>{content}</slot-content>
</my-component>
```

This tests:
- Custom elements (hyphenated tag names)
- Custom element boolean attributes
- Nested custom elements
- Inline expressions in attributes

## Test Cases

### Test 1: All Fixture Files Exist

```gleam
pub fn all_fixtures_exist_test() {
  let templates_dir = helpers.templates_dir()

  ["basic", "attributes", "control_flow", "events", "fragments", "custom_elements"]
  |> list.each(fn(name) {
    let path = templates_dir <> "/" <> name <> ".lustre"
    let assert Ok(True) = simplifile.is_file(path)
  })
}
```

### Test 2: All Fixtures Parse Successfully

```gleam
pub fn all_fixtures_parse_test() {
  let templates_dir = helpers.templates_dir()
  let assert Ok(files) = simplifile.get_files(templates_dir)

  files
  |> list.filter(fn(f) { string.ends_with(f, ".lustre") })
  |> list.each(fn(path) {
    let assert Ok(content) = simplifile.read(path)
    let assert Ok(_template) = parser.parse(content)
  })
}
```

### Test 3: Control Flow Fixture Has All Constructs

```gleam
pub fn control_flow_fixture_content_test() {
  let path = helpers.templates_dir() <> "/control_flow.lustre"
  let assert Ok(content) = simplifile.read(path)

  // Verify all control flow constructs present
  content |> string.contains("{#if") |> should.be_true()
  content |> string.contains("{:else}") |> should.be_true()
  content |> string.contains("{/if}") |> should.be_true()
  content |> string.contains("{#each") |> should.be_true()
  content |> string.contains("{/each}") |> should.be_true()
  content |> string.contains("{#case") |> should.be_true()
  content |> string.contains("{/case}") |> should.be_true()
}
```

## Verification Checklist

- [ ] All implementation steps completed
- [ ] All test cases pass
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] No regressions in existing functionality
- [ ] All template syntax features are covered
- [ ] Fixtures use types from project_template/src/types.gleam

## Notes

- Fixtures are designed to complement the existing fixtures in `test/fixtures/`
- Each fixture focuses on a specific feature area for easier debugging
- The control_flow fixture is the most comprehensive, testing all major features
- Custom elements fixture tests the special handling for hyphenated tags
- All templates should be valid and parseable by the template generator

## Files to Modify

- `test/e2e/fixtures/templates/basic.lustre` - Create basic elements fixture
- `test/e2e/fixtures/templates/attributes.lustre` - Create attributes fixture
- `test/e2e/fixtures/templates/control_flow.lustre` - Create control flow fixture
- `test/e2e/fixtures/templates/events.lustre` - Create events fixture
- `test/e2e/fixtures/templates/fragments.lustre` - Create fragments fixture
- `test/e2e/fixtures/templates/custom_elements.lustre` - Create custom elements fixture

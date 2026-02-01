# Task 003: Fixture Enhancement

## Description

Enhance the existing shared fixtures at `test/fixtures/` to ensure comprehensive coverage of all template syntax features. These fixtures are used by unit tests, integration tests, and E2E tests.

## Dependencies

- 000_test_restructure - Ensures fixtures stay at `test/fixtures/`

## Success Criteria

1. Fixtures at `test/fixtures/` cover all syntax features
2. New fixtures added for: events, fragments, custom elements
3. All fixtures use consistent type definitions
4. All fixtures parse without errors
5. Existing tests continue to pass

## Current Fixtures

Review existing fixtures:

```
test/fixtures/
├── simple/
│   └── basic.lustre       # Basic elements, text interpolation
├── attributes/
│   └── all_attrs.lustre   # Static, dynamic, boolean attrs, events
└── control_flow/
    └── full.lustre        # if/else, each, case, imports
```

## Gap Analysis

The existing fixtures cover most features but may need enhancement for:

1. **Events** - `all_attrs.lustre` has events but a dedicated fixture helps isolation
2. **Fragments** - Multiple root elements with `<> </>`
3. **Custom Elements** - Hyphenated tag names like `<my-component>`
4. **Edge Cases** - Empty params, self-closing tags, comments

## Implementation Steps

### 1. Audit Existing Fixtures

Read each fixture and document what it tests:

```bash
# Check current coverage
cat test/fixtures/simple/basic.lustre
cat test/fixtures/attributes/all_attrs.lustre
cat test/fixtures/control_flow/full.lustre
```

### 2. Add Events Fixture (if not covered)

Create `test/fixtures/events/handlers.lustre` if dedicated event testing is needed:

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
</form>
```

### 3. Add Fragments Fixture

Create `test/fixtures/fragments/multiple_roots.lustre`:

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

### 4. Add Custom Elements Fixture

Create `test/fixtures/custom_elements/web_components.lustre`:

```html
@params(
  content: String,
  is_active: Bool,
)

<my-component class="custom">
  <slot-content>{content}</slot-content>
  {#if is_active}
    <status-indicator active></status-indicator>
  {/if}
</my-component>
```

### 5. Add Edge Cases Fixture

Create `test/fixtures/edge_cases/special.lustre`:

```html
@params()

<div>
  <!-- HTML comment should be ignored -->
  <br/>
  <input type="text"/>
  <span>Text with {{escaped braces}}</span>
</div>
```

### 6. Update Types if Needed

If fixtures need shared types, document them for the project template (task 002).

## Test Cases

### Test 1: All Fixtures Parse Successfully

```gleam
pub fn all_fixtures_parse_test() {
  let assert Ok(files) = simplifile.get_files("test/fixtures")

  files
  |> list.filter(fn(f) { string.ends_with(f, ".lustre") })
  |> list.each(fn(path) {
    let assert Ok(content) = simplifile.read(path)
    let assert Ok(_template) = parser.parse(content)
  })
}
```

### Test 2: Fixture Coverage Check

Manually verify each syntax feature has fixture coverage:

- [ ] Basic elements and nesting
- [ ] Text interpolation `{expr}`
- [ ] Static attributes
- [ ] Dynamic attributes `attr={expr}`
- [ ] Boolean attributes
- [ ] Event handlers `@event={handler}`
- [ ] If/else blocks
- [ ] Each loops with index
- [ ] Case expressions
- [ ] Imports
- [ ] Fragments `<> </>`
- [ ] Custom elements
- [ ] Self-closing tags
- [ ] HTML comments
- [ ] Escaped braces `{{`

## Verification Checklist

- [ ] All implementation steps completed
- [ ] All test cases pass
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] No regressions in existing functionality
- [ ] All template syntax features are covered
- [ ] Existing integration tests still pass

## Notes

- Only add fixtures that aren't already covered by existing ones
- Keep fixtures minimal - each should focus on specific features
- Fixtures should be reusable by both integration and E2E tests
- Type references in fixtures should match project template types (task 002)
- The control_flow/full.lustre fixture is comprehensive - avoid duplicating its coverage

## Files to Modify

- `test/fixtures/events/handlers.lustre` - Create if needed
- `test/fixtures/fragments/multiple_roots.lustre` - Create
- `test/fixtures/custom_elements/web_components.lustre` - Create
- `test/fixtures/edge_cases/special.lustre` - Create if needed

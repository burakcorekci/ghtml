# Task 005: Add Lustre Dev Dependency

## Description

Add Lustre as a dev-dependency to the main project's `gleam.toml`. This enables SSR testing using `lustre/element.to_string()` directly in the test suite without requiring a separate compilation step.

## Dependencies

- None - this is a standalone configuration change

## Success Criteria

1. Lustre is added to `[dev-dependencies]` in `gleam.toml`
2. `gleam build` succeeds after adding the dependency
3. `gleam test` succeeds after adding the dependency
4. `lustre/element` module is importable in test files

## Implementation Steps

### 1. Determine Latest Stable Lustre Version

Check the latest stable version of Lustre:

```bash
# Check Hex.pm for latest version
# As of the knowledge cutoff, Lustre 4.x is the current major version
```

### 2. Update gleam.toml

Add Lustre to the dev-dependencies section in `gleam.toml`:

```toml
[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
lustre = ">= 4.0.0 and < 5.0.0"
```

### 3. Fetch Dependencies

Run `gleam deps download` to fetch the new dependency:

```bash
gleam deps download
```

### 4. Verify Import Works

Create a simple test to verify Lustre is accessible:

```gleam
import lustre/element

pub fn lustre_available_test() {
  // Just verify we can use element functions
  let el = element.text("Hello")
  let html = element.to_string(el)
  html |> should.equal("Hello")
}
```

### 5. Update Project Template Fixture

Ensure the project template fixture (task 002) uses the same Lustre version:

```toml
# test/e2e/fixtures/project_template/gleam.toml
[dependencies]
lustre = ">= 4.0.0 and < 5.0.0"
```

## Test Cases

### Test 1: Lustre Element Import Works

```gleam
import lustre/element
import gleeunit/should

pub fn lustre_element_to_string_test() {
  element.text("Hello, World!")
  |> element.to_string()
  |> should.equal("Hello, World!")
}
```

### Test 2: HTML Elements Work

```gleam
import lustre/element/html
import lustre/element
import gleeunit/should

pub fn html_element_to_string_test() {
  html.div([], [element.text("Content")])
  |> element.to_string()
  |> should.equal("<div>Content</div>")
}
```

### Test 3: Attributes Work

```gleam
import lustre/element/html
import lustre/attribute
import lustre/element
import gleeunit/should

pub fn html_with_attributes_test() {
  html.div([attribute.class("container")], [element.text("Hello")])
  |> element.to_string()
  |> should.equal("<div class=\"container\">Hello</div>")
}
```

## Verification Checklist

- [ ] All implementation steps completed
- [ ] All test cases pass
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] No regressions in existing functionality
- [ ] Lustre version matches across main project and fixture

## Notes

- Lustre is added as a **dev-dependency** since the generator itself doesn't depend on Lustre at runtime
- The generated code depends on Lustre, but that's the responsibility of the projects using the generator
- SSR tests (task 007) will use `element.to_string()` for verification
- The project template fixture must use a compatible Lustre version
- Version range `>= 4.0.0 and < 5.0.0` allows patch updates while avoiding breaking changes

## Files to Modify

- `gleam.toml` - Add lustre to dev-dependencies
- `test/e2e/fixtures/project_template/gleam.toml` - Ensure version matches (if created in task 002)

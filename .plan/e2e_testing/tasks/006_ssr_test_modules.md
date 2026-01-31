# Task 006: SSR Test Modules

## Description

Pre-generate Gleam modules from the template fixtures that can be imported directly by SSR tests. This avoids the need to generate code at test runtime for SSR verification, making tests faster and more focused on verifying HTML output.

## Dependencies

- 003_template_test_fixtures - Needs the `.lustre` fixtures to generate from
- 005_lustre_dev_dependency - Needs Lustre for the generated modules to compile

## Success Criteria

1. Generated modules exist at `test/e2e/generated/`
2. Each fixture has a corresponding `.gleam` file
3. All generated modules compile with `gleam build`
4. Generated modules can be imported by test files
5. A generation script exists to regenerate modules when fixtures change

## Implementation Steps

### 1. Create Generation Script

Add a justfile command to generate the SSR test modules:

```just
# Generate SSR test modules from E2E fixtures
e2e-generate:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Generating SSR test modules..."

    # Run the generator for each fixture
    for fixture in test/e2e/fixtures/templates/*.lustre; do
        filename=$(basename "$fixture" .lustre)
        output="test/e2e/generated/${filename}.gleam"

        # Use the generator to create the output
        gleam run -m lustre_template_gen -- test/e2e/fixtures/templates

        echo "  Generated: $output"
    done

    echo "✓ SSR test modules generated"
```

Alternatively, create a dedicated Gleam module that generates these files:

### 2. Create E2E Generator Module

Create `src/lustre_template_gen/e2e_generator.gleam` (or use CLI):

The simplest approach is to use the existing CLI with a target directory:

```bash
# Generate modules for the templates directory
gleam run -m lustre_template_gen -- test/e2e/fixtures/templates
```

But since the output needs to go to `test/e2e/generated/`, we may need a custom approach.

### 3. Generate Modules Manually (Initial Setup)

For the initial setup, generate each module:

**test/e2e/generated/basic.gleam:**
```gleam
// @generated from test/e2e/fixtures/templates/basic.lustre
// hash: [computed hash]

import lustre/element.{type Element}
import lustre/element/html
import lustre/attribute

pub fn render(title title: String, message message: String) -> Element(msg) {
  html.div([attribute.class("container")], [
    html.h1([], [element.text(title)]),
    html.p([attribute.class("message")], [element.text(message)]),
  ])
}
```

**test/e2e/generated/attributes.gleam:**
```gleam
// @generated from test/e2e/fixtures/templates/attributes.lustre
// hash: [computed hash]

import lustre/element.{type Element}
import lustre/element/html
import lustre/attribute

pub fn render(
  id id: String,
  name name: String,
  value value: String,
  is_disabled is_disabled: Bool,
  is_checked is_checked: Bool,
) -> Element(msg) {
  html.form([attribute.id(id), attribute.class("form")], [
    html.input([
      attribute.type_("text"),
      attribute.name(name),
      attribute.value(value),
      attribute.disabled(True),
      attribute.class("input"),
    ]),
    html.input([
      attribute.type_("checkbox"),
      attribute.checked(True),
    ]),
    html.button([attribute.type_("submit"), attribute.class("btn")], [
      element.text("Submit"),
    ]),
  ])
}
```

### 4. Generate All Fixture Modules

Generate modules for all fixtures:
- `test/e2e/generated/basic.gleam`
- `test/e2e/generated/attributes.gleam`
- `test/e2e/generated/control_flow.gleam`
- `test/e2e/generated/events.gleam`
- `test/e2e/generated/fragments.gleam`
- `test/e2e/generated/custom_elements.gleam`

### 5. Add .gitkeep and Update .gitignore

The generated files should be committed so tests can run without generation:

```
test/e2e/generated/
├── basic.gleam
├── attributes.gleam
├── control_flow.gleam
├── events.gleam
├── fragments.gleam
└── custom_elements.gleam
```

### 6. Create Regeneration Command

Add to justfile:

```just
# Regenerate E2E SSR test modules from fixtures
e2e-regen:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Regenerating SSR test modules..."

    # Clear existing generated files (except .gitkeep)
    find test/e2e/generated -name "*.gleam" -delete

    # Generate from each fixture using the template generator
    for fixture in test/e2e/fixtures/templates/*.lustre; do
        filename=$(basename "$fixture" .lustre)

        # Parse and generate
        content=$(cat "$fixture")
        # ... invoke generator programmatically
    done

    echo "✓ SSR test modules regenerated"
```

## Test Cases

### Test 1: All Generated Modules Exist

```gleam
pub fn all_generated_modules_exist_test() {
  let generated_dir = helpers.generated_dir()

  ["basic", "attributes", "control_flow", "events", "fragments", "custom_elements"]
  |> list.each(fn(name) {
    let path = generated_dir <> "/" <> name <> ".gleam"
    let assert Ok(True) = simplifile.is_file(path)
  })
}
```

### Test 2: Generated Modules Are Valid

```gleam
pub fn generated_modules_compile_test() {
  // If we can import them, they compile
  // This is implicitly tested by the module imports in SSR tests
}
```

### Test 3: Generated Modules Have Headers

```gleam
pub fn generated_modules_have_headers_test() {
  let generated_dir = helpers.generated_dir()
  let assert Ok(files) = simplifile.get_files(generated_dir)

  files
  |> list.filter(fn(f) { string.ends_with(f, ".gleam") })
  |> list.each(fn(path) {
    let assert Ok(content) = simplifile.read(path)
    content |> string.contains("@generated") |> should.be_true()
  })
}
```

## Verification Checklist

- [ ] All implementation steps completed
- [ ] All test cases pass
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes
- [ ] Code follows project conventions (see CLAUDE.md)
- [ ] No regressions in existing functionality
- [ ] All generated modules compile
- [ ] Generated modules match fixture structure

## Notes

- Generated modules are committed to the repo for CI simplicity
- A regeneration command allows updating when fixtures change
- The generated modules use the same code as the template generator produces
- Modules are placed in `test/e2e/generated/` to avoid scanner pickup
- Import paths in generated modules must match project structure

## Files to Modify

- `test/e2e/generated/basic.gleam` - Generate from basic.lustre
- `test/e2e/generated/attributes.gleam` - Generate from attributes.lustre
- `test/e2e/generated/control_flow.gleam` - Generate from control_flow.lustre
- `test/e2e/generated/events.gleam` - Generate from events.lustre
- `test/e2e/generated/fragments.gleam` - Generate from fragments.lustre
- `test/e2e/generated/custom_elements.gleam` - Generate from custom_elements.lustre
- `justfile` - Add e2e-regen command

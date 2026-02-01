# Task 001: Rename Simple Example

## Description

Rename the existing `examples/simple/` directory to `examples/01_simple/` for consistency with the numbered example structure. Add a README explaining basic template concepts.

## Dependencies

None - this is the first task.

## Success Criteria

1. Directory renamed from `examples/simple/` to `examples/01_simple/`
2. README.md created with introduction to `.lustre` files
3. Project still builds and runs correctly
4. `gleam.toml` name updated if necessary

## Implementation Steps

### 1. Rename Directory

```bash
mv examples/simple examples/01_simple
```

### 2. Create README.md

Create `examples/01_simple/README.md` with:
- Introduction to Lustre Template Generator
- Basic concepts: params, static attributes, text interpolation
- Running instructions
- Key files to examine

### 3. Update gleam.toml

Update the project name in `gleam.toml` if needed:
```toml
name = "example_01_simple"
```

### 4. Verify

- Run `gleam build` in the example directory
- Run `gleam run -m lustre/dev start` to verify browser operation

## README Content

```markdown
# Example 01: Simple Template

## Concepts

This example introduces the basics of Lustre templates:
- `@params()` declaration for component parameters
- Static HTML attributes like `class="greeting"`
- Text interpolation with `{expression}`

## Prerequisites

None - start here!

## Features Demonstrated

### Template Parameters

```html
@params(name: String)
```

Parameters define what data your component accepts. They become function arguments in the generated Gleam code.

### Static Attributes

```html
<div class="greeting">
```

Standard HTML attributes are passed through as Lustre `attribute.class()` calls.

### Text Interpolation

```html
<h1>Hello, {name}!</h1>
```

Expressions in curly braces are interpolated. The expression must evaluate to `String`.

## Running the Example

1. Generate Gleam from templates:
   ```bash
   cd ../..  # Go to project root
   just run
   ```

2. Build and run:
   ```bash
   cd examples/01_simple
   gleam deps download
   gleam run -m lustre/dev start
   ```

3. Open http://localhost:1234 in your browser

## Key Files

- `src/components/greeting.lustre` - The template file
- `src/components/greeting.gleam` - Generated Gleam code (after running `just run`)
- `src/simple_example.gleam` - Main app that uses the component

## Exercises

1. Add a second parameter to the greeting component
2. Add another HTML element to the template
3. Try using a function call like `{string.uppercase(name)}`
```

## Verification Checklist

- [ ] Directory renamed successfully
- [ ] README.md created with all sections
- [ ] `gleam build` succeeds
- [ ] `gleam run -m lustre/dev start` works in browser
- [ ] No broken references to old path

## Files to Modify

- `examples/simple/` -> `examples/01_simple/` (rename)
- `examples/01_simple/README.md` (create)
- `examples/01_simple/gleam.toml` (update name)

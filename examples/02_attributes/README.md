# Example 02: Attributes

## Concepts

This example demonstrates all attribute types in Lustre templates:
- Static attributes with literal values
- Dynamic attributes with Gleam expressions
- Boolean attributes for HTML form elements
- Conditional attribute values

## Prerequisites

Complete Example 01 first to understand basic template syntax.

## Features Demonstrated

### Static Attributes

Static attributes have literal string values:

```html
<input type="text" class="input" />
```

Generates:
```gleam
html.input([attribute.type_("text"), attribute.class("input")], [])
```

### Dynamic Attributes

Dynamic attributes use curly braces for Gleam expressions:

```html
<input value={current_value} placeholder={hint} />
```

Generates:
```gleam
html.input([attribute.value(current_value), attribute.placeholder(hint)], [])
```

### Boolean Attributes

HTML boolean attributes like `required`, `disabled`, `checked`:

```html
<input type="checkbox" checked={is_checked} required />
```

For standard HTML elements:
- `checked={expr}` -> `attribute.checked(expr)`
- `required` (no value) -> `attribute.required(True)`
- `disabled` -> `attribute.disabled(True)`

### Conditional Attributes

Use case expressions for conditional attribute values:

```html
<a
  target={case is_external { True -> "_blank" False -> "_self" }}
  rel={case is_external { True -> "noopener noreferrer" False -> "" }}
>
```

### Known vs Unknown Attributes

The generator recognizes common HTML attributes and maps them to Lustre functions:
- `class` -> `attribute.class()`
- `id` -> `attribute.id()`
- `href` -> `attribute.href()`
- `src` -> `attribute.src()`
- etc.

Unknown attributes use the generic function:
```html
<div data-custom="value">
```
Generates: `attribute.attribute("data-custom", "value")`

## Running the Example

1. Generate Gleam from templates:
   ```bash
   cd ../..  # Go to project root
   just run
   ```

2. Build and run:
   ```bash
   cd examples/02_attributes
   gleam deps download
   gleam run -m lustre/dev start
   ```

3. Open http://localhost:1234 in your browser

## Key Files

- `src/components/form_field.lustre` - Static + dynamic attributes
- `src/components/checkbox_field.lustre` - Boolean attributes
- `src/components/link_button.lustre` - Conditional attributes
- `src/app.gleam` - Main app using all components

## Exercises

1. Add a `disabled` boolean attribute to form_field
2. Create a new component with `aria-*` attributes
3. Add a `data-testid` attribute for testing

# Task 002: Create Attributes Example

## Description

Create `examples/02_attributes/` demonstrating all attribute types: static, dynamic, and boolean attributes.

## Dependencies

- 001: Rename simple example (directory structure established)

## Success Criteria

1. Example project created at `examples/02_attributes/`
2. Templates demonstrate static, dynamic, and boolean attributes
3. README explains each attribute type with examples
4. Application runs and shows interactive form

## Implementation Steps

### 1. Create Project Structure

```bash
mkdir -p examples/02_attributes/src/components
mkdir -p examples/02_attributes/assets
```

### 2. Create gleam.toml

```toml
name = "example_02_attributes"
version = "0.1.0"
target = "javascript"

[dependencies]
lustre = "~> 5.0"

[dev-dependencies]
lustre_dev_tools = "~> 2.0"

[tools.lustre.html]
title = "Attributes Example"
stylesheets = [{ href = "/styles.css" }]
```

### 3. Create Components

#### form_field.lustre
```html
@params(
  value: String,
  hint: String,
  is_required: Bool,
)

<div class="field">
  <label class="label">Name</label>
  <input
    type="text"
    class="input"
    value={value}
    placeholder={hint}
    required
  />
</div>
```

#### link_button.lustre
```html
@params(
  url: String,
  label: String,
  is_external: Bool,
)

<a
  href={url}
  class="btn"
  target={case is_external { True -> "_blank" False -> "_self" }}
  rel={case is_external { True -> "noopener noreferrer" False -> "" }}
>
  {label}
</a>
```

#### checkbox_field.lustre
```html
@params(
  label: String,
  is_checked: Bool,
)

<label class="checkbox">
  <input
    type="checkbox"
    checked
  />
  <span>{label}</span>
</label>
```

### 4. Create Main App

Create `src/app.gleam` with a form that demonstrates all components.

### 5. Create README

Explain:
- Static attributes: `class="input"`, `type="text"`
- Dynamic attributes: `value={variable}`, `placeholder={hint}`
- Boolean attributes: `required`, `checked`, `disabled`
- Known attributes (use Lustre functions) vs unknown (use `attribute.attribute()`)

### 6. Create Styles

Basic CSS for form styling in `assets/styles.css`.

## Template Syntax Reference

### Static Attributes
```html
<input type="text" class="input" />
```
Generates: `attribute.type_("text")`, `attribute.class("input")`

### Dynamic Attributes
```html
<input value={current_value} placeholder={hint} />
```
Generates: `attribute.value(current_value)`, `attribute.placeholder(hint)`

### Boolean Attributes
```html
<input disabled required readonly />
```
Generates: `attribute.disabled(True)`, `attribute.required(True)`

For custom elements, boolean attrs use `attribute.attribute("name", "")`.

## Verification Checklist

- [ ] All template files created
- [ ] `just run` generates valid Gleam code
- [ ] `gleam build` succeeds
- [ ] App runs and form elements work
- [ ] README explains all attribute types
- [ ] Different attribute types visibly demonstrated

## Files to Create

- `examples/02_attributes/gleam.toml`
- `examples/02_attributes/README.md`
- `examples/02_attributes/assets/styles.css`
- `examples/02_attributes/src/app.gleam`
- `examples/02_attributes/src/components/form_field.lustre`
- `examples/02_attributes/src/components/link_button.lustre`
- `examples/02_attributes/src/components/checkbox_field.lustre`

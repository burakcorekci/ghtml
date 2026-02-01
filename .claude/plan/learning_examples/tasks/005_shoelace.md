# Task 005: Create Shoelace Example

## Description

Create `examples/05_shoelace/` demonstrating integration with Shoelace web components. Shows how custom elements (tags with `-`) are handled differently.

## Dependencies

- 001: Rename simple example (directory structure established)

## Success Criteria

1. Example project created at `examples/05_shoelace/`
2. Shoelace components load from CDN
3. Templates use custom elements correctly
4. Custom events like `@sl-change` work
5. README explains web component integration

## Implementation Steps

### 1. Create Project Structure

```bash
mkdir -p examples/05_shoelace/src/components
mkdir -p examples/05_shoelace/assets
```

### 2. Create gleam.toml with Shoelace CDN

```toml
name = "example_05_shoelace"
version = "0.1.0"
target = "javascript"

[dependencies]
lustre = "~> 5.0"

[dev-dependencies]
lustre_dev_tools = "~> 2.0"

[tools.lustre.html]
title = "Shoelace Example"
scripts = [
  { type = "module", src = "https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2.19.0/cdn/shoelace-autoloader.js" }
]
stylesheets = [
  { href = "https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2.19.0/cdn/themes/light.css" },
  { href = "/styles.css" }
]
```

### 3. Create Components

#### sl_button.lustre
```html
@params(
  label: String,
  variant: String,
  on_click: fn() -> msg,
)

<sl-button variant={variant} @click={on_click()}>
  {label}
</sl-button>
```

#### sl_input.lustre
```html
@params(
  value: String,
  label: String,
  placeholder: String,
  on_input: fn(String) -> msg,
)

<sl-input
  value={value}
  label={label}
  placeholder={placeholder}
  @sl-input={on_input}
/>
```

#### sl_checkbox.lustre
```html
@params(
  label: String,
  is_checked: Bool,
  on_change: fn() -> msg,
)

<sl-checkbox checked @sl-change={on_change()}>
  {label}
</sl-checkbox>
```

#### sl_dialog.lustre
```html
@params(
  title: String,
  is_open: Bool,
  on_close: fn() -> msg,
)

<sl-dialog label={title} open @sl-hide={on_close()}>
  <p>This is a Shoelace dialog component.</p>
  <sl-button slot="footer" variant="primary" @click={on_close()}>
    Close
  </sl-button>
</sl-dialog>
```

#### sl_card.lustre
```html
@params(
  title: String,
  body: String,
  image_src: String,
)

<sl-card class="card">
  <img slot="image" src={image_src} alt="" />
  <strong>{title}</strong>
  <p>{body}</p>
</sl-card>
```

#### sl_select.lustre
```html
@import(app/types.{type Option})

@params(
  label: String,
  options: List(Option),
  selected: String,
  on_change: fn(String) -> msg,
)

<sl-select label={label} value={selected} @sl-change={on_change}>
  {#each options as opt, _}
    <sl-option value={opt.value}>{opt.label}</sl-option>
  {/each}
</sl-select>
```

### 4. Create Types Module

```gleam
// src/types.gleam
pub type Option {
  Option(value: String, label: String)
}
```

### 5. Create Main App

Demonstrate:
- Button variants (default, primary, success, warning, danger)
- Input with real-time binding
- Checkbox toggle
- Dialog open/close
- Card layout
- Select dropdown

### 6. Create README

Explain:

**Custom Elements**
- Tags with `-` like `<sl-button>` are custom elements
- Generated as `element("sl-button", attrs, children)` not `html.sl_button()`

**Custom Events**
- Shoelace uses prefixed events: `sl-change`, `sl-input`, `sl-hide`
- Use `@sl-change={handler}` syntax
- Generated as `event.on("sl-change", handler)`

**Boolean Attributes on Custom Elements**
- Boolean attrs use `attribute.attribute("name", "")` format
- Example: `checked` becomes `attribute.attribute("checked", "")`

**Slots**
- Use `slot="name"` attribute for Shoelace slots
- Example: `<span slot="label">Title</span>`

## Key Insight: Generated Code Difference

Standard HTML:
```html
<button class="btn">Click</button>
```
Generates:
```gleam
html.button([attribute.class("btn")], [text("Click")])
```

Custom Element:
```html
<sl-button variant="primary">Click</sl-button>
```
Generates:
```gleam
element("sl-button", [attribute.attribute("variant", "primary")], [text("Click")])
```

## Verification Checklist

- [ ] Shoelace CSS and JS load from CDN
- [ ] All components render correctly
- [ ] Button clicks trigger events
- [ ] Input updates on typing
- [ ] Checkbox toggles
- [ ] Dialog opens and closes
- [ ] Select dropdown works
- [ ] README explains custom element handling

## Files to Create

- `examples/05_shoelace/gleam.toml`
- `examples/05_shoelace/README.md`
- `examples/05_shoelace/assets/styles.css`
- `examples/05_shoelace/src/app.gleam`
- `examples/05_shoelace/src/types.gleam`
- `examples/05_shoelace/src/components/sl_button.lustre`
- `examples/05_shoelace/src/components/sl_input.lustre`
- `examples/05_shoelace/src/components/sl_checkbox.lustre`
- `examples/05_shoelace/src/components/sl_dialog.lustre`
- `examples/05_shoelace/src/components/sl_card.lustre`
- `examples/05_shoelace/src/components/sl_select.lustre`

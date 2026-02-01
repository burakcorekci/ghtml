# Task 006: Create Material Web Example

## Description

Create `examples/06_material_web/` demonstrating integration with Google's Material Web components.

## Dependencies

- 001: Rename simple example (directory structure established)

## Success Criteria

1. Example project created at `examples/06_material_web/`
2. Material Web components load from CDN
3. Templates use md-* custom elements correctly
4. README explains Material Web integration

## Implementation Steps

### 1. Create Project Structure

```bash
mkdir -p examples/06_material_web/src/components
mkdir -p examples/06_material_web/assets
```

### 2. Create gleam.toml with Material Web CDN

```toml
name = "example_06_material_web"
version = "0.1.0"
target = "javascript"

[dependencies]
lustre = "~> 5.0"

[dev-dependencies]
lustre_dev_tools = "~> 2.0"

[tools.lustre.html]
title = "Material Web Example"
scripts = [
  { type = "module", src = "https://esm.run/@material/web/all.js" }
]
stylesheets = [
  { href = "/styles.css" }
]
```

### 3. Create Components

#### md_button.lustre
```html
@params(
  label: String,
  on_click: fn() -> msg,
)

<md-filled-button @click={on_click()}>
  {label}
</md-filled-button>
```

#### md_outlined_button.lustre
```html
@params(
  label: String,
  on_click: fn() -> msg,
)

<md-outlined-button @click={on_click()}>
  {label}
</md-outlined-button>
```

#### md_text_button.lustre
```html
@params(
  label: String,
  on_click: fn() -> msg,
)

<md-text-button @click={on_click()}>
  {label}
</md-text-button>
```

#### md_textfield.lustre
```html
@params(
  value: String,
  label: String,
  on_input: fn(String) -> msg,
)

<md-outlined-text-field
  value={value}
  label={label}
  @input={on_input}
/>
```

#### md_checkbox.lustre
```html
@params(
  is_checked: Bool,
  on_change: fn() -> msg,
)

<md-checkbox checked @change={on_change()} />
```

#### md_switch.lustre
```html
@params(
  is_on: Bool,
  on_change: fn() -> msg,
)

<md-switch selected @change={on_change()} />
```

#### md_fab.lustre
```html
@params(
  icon: String,
  on_click: fn() -> msg,
)

<md-fab @click={on_click()}>
  <md-icon slot="icon">{icon}</md-icon>
</md-fab>
```

#### md_list.lustre
```html
@import(app/types.{type ListItem})

@params(items: List(ListItem))

<md-list>
  {#each items as item, _}
    <md-list-item>
      <span slot="headline">{item.headline}</span>
      <span slot="supporting-text">{item.supporting}</span>
    </md-list-item>
  {/each}
</md-list>
```

### 4. Create Types Module

```gleam
// src/types.gleam
pub type ListItem {
  ListItem(id: String, headline: String, supporting: String)
}
```

### 5. Create Main App

Demonstrate:
- Button variants (filled, outlined, text)
- Text field input
- Checkbox and switch toggles
- FAB (floating action button)
- List component

### 6. Create Styles

Material Web theming via CSS custom properties:

```css
:root {
  --md-sys-color-primary: #6750a4;
  --md-sys-color-on-primary: #ffffff;
  --md-sys-color-surface: #fffbfe;
}

body {
  font-family: Roboto, system-ui, sans-serif;
  background: var(--md-sys-color-surface);
}
```

### 7. Create README

Explain:

**Material Web Components**
- Google's official Material Design 3 components
- All use `md-*` prefix: `md-filled-button`, `md-outlined-text-field`
- Loaded via ES modules from CDN

**Component Categories**
- Buttons: `md-filled-button`, `md-outlined-button`, `md-text-button`, `md-fab`
- Inputs: `md-outlined-text-field`, `md-filled-text-field`
- Selection: `md-checkbox`, `md-switch`, `md-radio`
- Display: `md-list`, `md-dialog`, `md-menu`

**Events**
- Standard DOM events work: `@click`, `@input`, `@change`
- No custom event prefixes like Shoelace

**Theming**
- Use CSS custom properties for theming
- Material Design 3 token system

## Verification Checklist

- [ ] Material Web JS loads from CDN
- [ ] All button variants render
- [ ] Text field accepts input
- [ ] Checkbox toggles
- [ ] Switch toggles
- [ ] FAB button works
- [ ] List renders items
- [ ] README explains Material Web usage

## Files to Create

- `examples/06_material_web/gleam.toml`
- `examples/06_material_web/README.md`
- `examples/06_material_web/assets/styles.css`
- `examples/06_material_web/src/app.gleam`
- `examples/06_material_web/src/types.gleam`
- `examples/06_material_web/src/components/md_button.lustre`
- `examples/06_material_web/src/components/md_outlined_button.lustre`
- `examples/06_material_web/src/components/md_text_button.lustre`
- `examples/06_material_web/src/components/md_textfield.lustre`
- `examples/06_material_web/src/components/md_checkbox.lustre`
- `examples/06_material_web/src/components/md_switch.lustre`
- `examples/06_material_web/src/components/md_fab.lustre`
- `examples/06_material_web/src/components/md_list.lustre`

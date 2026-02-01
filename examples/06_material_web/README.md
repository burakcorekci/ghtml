# Example 06: Material Web Components

## Concepts

This example demonstrates integration with [Material Web](https://material-web.dev/), Google's official Material Design 3 web components. It shows how the template generator handles custom elements with standard DOM events.

## Prerequisites

Complete Examples 01-05 first to understand basic template syntax, attributes, events, control flow, and web component integration with Shoelace.

## Material Web vs Shoelace

Unlike Shoelace which uses custom prefixed events (like `sl-input`, `sl-change`), Material Web components use **standard DOM events** (`input`, `change`, `click`). This means you can use Lustre's standard event handlers with simpler function types.

### Event Comparison

**Shoelace (custom events with decoders):**
```html
@import(gleam/dynamic/decode)
@params(on_input: decode.Decoder(msg))

<sl-input @sl-input={on_input} />
```

**Material Web (standard events with functions):**
```html
@params(on_input: fn(String) -> msg)

<md-outlined-text-field @input={on_input} />
```

Material Web's use of standard DOM events means simpler handler types - you use `fn(String) -> msg` instead of decoders.

## Loading Material Web

Material Web components are loaded via ES modules from a CDN:

```toml
[tools.lustre.html]
scripts = [
  { type = "module", src = "https://esm.run/@material/web/all.js" }
]
```

This loads all components. For production, consider loading only the components you need:
```javascript
import '@material/web/button/filled-button.js';
import '@material/web/textfield/outlined-text-field.js';
```

## Component Categories

Material Web provides components in several categories:

### Buttons
- `md-filled-button` - Primary action button with filled background
- `md-outlined-button` - Secondary action with border outline
- `md-text-button` - Tertiary action with text only
- `md-fab` - Floating action button

### Inputs
- `md-outlined-text-field` - Text input with outline style
- `md-filled-text-field` - Text input with filled style

### Selection Controls
- `md-checkbox` - Checkbox with `checked` boolean attribute
- `md-switch` - Toggle switch with `selected` boolean attribute
- `md-radio` - Radio button

### Display Components
- `md-list` - List container
- `md-list-item` - List item with slots for content
- `md-dialog` - Modal dialog
- `md-menu` - Dropdown menu

## Boolean Attributes

Material Web uses different boolean attribute names than standard HTML:

| Component | Boolean Attribute |
|-----------|-------------------|
| `md-checkbox` | `checked` |
| `md-switch` | `selected` |
| `md-dialog` | `open` |

In templates, use conditional rendering to toggle boolean attributes:

```html
{#if is_on}
  <md-switch selected @click={on_click()} />
{:else}
  <md-switch @click={on_click()} />
{/if}
```

## Slots

Material Web components use slots for content placement:

```html
<md-list-item>
  <span slot="headline">Title</span>
  <span slot="supporting-text">Description</span>
</md-list-item>

<md-fab @click={on_click()}>
  <md-icon slot="icon">add</md-icon>
</md-fab>
```

## Theming

Material Web uses CSS custom properties for theming. Set them on `:root` or any parent element:

```css
:root {
  --md-sys-color-primary: #6750a4;
  --md-sys-color-on-primary: #ffffff;
  --md-sys-color-surface: #fffbfe;
}
```

Material Design 3 provides an extensive token system. See the [Material Design 3 documentation](https://m3.material.io/) for the full list of customizable tokens.

## Components in This Example

### md_button.lustre
Filled button variant with click handler:
```html
@params(
  label: String,
  on_click: fn() -> msg,
)

<md-filled-button @click={on_click()}>
  {label}
</md-filled-button>
```

### md_textfield.lustre
Outlined text field with standard @input event:
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

### md_checkbox.lustre
Checkbox with conditional `checked` attribute and click handler:
```html
@params(
  is_checked: Bool,
  on_change: fn() -> msg,
)

{#if is_checked}
  <md-checkbox checked @click={on_change()} />
{:else}
  <md-checkbox @click={on_change()} />
{/if}
```

### md_switch.lustre
Switch with conditional `selected` attribute:
```html
@params(
  is_on: Bool,
  on_change: fn() -> msg,
)

{#if is_on}
  <md-switch selected @click={on_change()} />
{:else}
  <md-switch @click={on_change()} />
{/if}
```

### md_fab.lustre
Floating action button with icon slot:
```html
@params(
  icon: String,
  on_click: fn() -> msg,
)

<md-fab @click={on_click()}>
  <md-icon slot="icon">{icon}</md-icon>
</md-fab>
```

### md_list.lustre
List with `{#each}` for dynamic items:
```html
@import(types.{type ListItem})

@params(items: List(ListItem))

<md-list>
  {#each items as item, idx}
    <md-list-item>
      <span slot="headline">{item.headline}</span>
      <span slot="supporting-text">{item.supporting}</span>
    </md-list-item>
  {/each}
</md-list>
```

## Running the Example

1. Generate Gleam from templates:
   ```bash
   cd examples/06_material_web
   just codegen
   ```

2. Build and run:
   ```bash
   gleam deps download
   gleam run -m lustre/dev start
   ```

3. Open http://localhost:1234 in your browser

## Key Files

- `src/types.gleam` - Custom types used by components
- `src/components/md_button.lustre` - Filled button
- `src/components/md_outlined_button.lustre` - Outlined button
- `src/components/md_text_button.lustre` - Text button
- `src/components/md_textfield.lustre` - Text field with @input
- `src/components/md_checkbox.lustre` - Checkbox with boolean attr
- `src/components/md_switch.lustre` - Switch with boolean attr
- `src/components/md_fab.lustre` - FAB with icon slot
- `src/components/md_list.lustre` - List with {#each}
- `src/app.gleam` - Main app demonstrating all components

## Exercises

1. Add an `<md-dialog>` component with open/close functionality
2. Create an `<md-filled-text-field>` variant of the text field
3. Add `<md-radio>` buttons for single selection
4. Implement an `<md-menu>` for dropdown actions

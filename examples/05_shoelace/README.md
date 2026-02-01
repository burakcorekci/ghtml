# Example 05: Shoelace Web Components

## Concepts

This example demonstrates integration with [Shoelace](https://shoelace.style/), a popular web component library. It shows how the template generator handles custom elements differently from standard HTML elements.

## Prerequisites

Complete Examples 01-04 first to understand basic template syntax, attributes, events, and control flow.

## Custom Elements vs Standard HTML

The key insight is that tags containing a hyphen (like `<sl-button>`) are treated as custom elements and generate different code than standard HTML tags.

### Standard HTML Element

```html
<button class="btn">Click</button>
```

Generates:
```gleam
html.button([attribute.class("btn")], [html.text("Click")])
```

### Custom Element

```html
<sl-button variant="primary">Click</sl-button>
```

Generates:
```gleam
element("sl-button", [attribute.attribute("variant", "primary")], [html.text("Click")])
```

Notice the differences:
1. Uses `element()` instead of `html.sl_button()` (which doesn't exist)
2. Uses `attribute.attribute()` for all attributes (no special handling for `class`, `id`, etc.)

## Custom Events and Decoders

Shoelace components emit prefixed events like `sl-change`, `sl-input`, `sl-hide`. The template generator uses Lustre's `event.on()` for these, which requires a **decoder** rather than a direct message.

### Template Syntax

```html
<sl-input @sl-input={on_input_decoder} />
<sl-checkbox @sl-change={on_change_decoder} />
```

Generates:
```gleam
event.on("sl-input", on_input_decoder)
event.on("sl-change", on_change_decoder)
```

### Creating Decoders

For events that don't need data, use `decode.success()`:
```gleam
// Always returns ToggleCheckbox message
decode.success(ToggleCheckbox)
```

For events that need to extract data, create a decoder:
```gleam
// Extract value from event.target.value
fn decode_input_value(to_msg: fn(String) -> msg) -> decode.Decoder(msg) {
  decode.at(["target", "value"], decode.string)
  |> decode.map(to_msg)
}
```

This is different from standard HTML events like `@click` which use Lustre's built-in handlers that accept direct messages.

## Boolean Attributes on Custom Elements

For custom elements, boolean attributes use `attribute.attribute("name", "")`:

```html
<sl-checkbox checked>Label</sl-checkbox>
```

Generates:
```gleam
element("sl-checkbox", [attribute.attribute("checked", "")], [html.text("Label")])
```

This differs from standard HTML boolean attributes which use `attribute.checked(True)`.

## Slots

Shoelace uses slots for content placement. In templates, slots are just regular attributes:

```html
<sl-card>
  <img slot="image" src={url} />
  <span slot="header">Title</span>
  <p>Body content</p>
</sl-card>
```

The `slot` attribute is passed through as a regular attribute.

## Components in This Example

### sl_button.lustre
Basic button with variant support. Uses standard `@click` event:
```html
<sl-button variant={variant} @click={on_click()}>
  {label}
</sl-button>
```

### sl_input.lustre
Text input with custom `@sl-input` event. Takes a decoder:
```html
@import(gleam/dynamic/decode)

@params(
  value: String,
  label: String,
  placeholder: String,
  on_input: decode.Decoder(msg),
)

<sl-input
  value={value}
  label={label}
  placeholder={placeholder}
  @sl-input={on_input}
/>
```

### sl_checkbox.lustre
Checkbox with conditional `checked` boolean attribute and `@sl-change`:
```html
{#if is_checked}
  <sl-checkbox checked @sl-change={on_change}>
    {label}
  </sl-checkbox>
{:else}
  <sl-checkbox @sl-change={on_change}>
    {label}
  </sl-checkbox>
{/if}
```

### sl_dialog.lustre
Modal dialog with `@sl-hide` event for close detection:
```html
<sl-dialog label={title} open @sl-hide={on_close_decoder}>
  <p>Content</p>
  <sl-button slot="footer" variant="primary" @click={on_close_click()}>
    Close
  </sl-button>
</sl-dialog>
```

Note: `@sl-hide` uses a decoder, while `@click` uses a direct function call.

### sl_card.lustre
Card with image slot:
```html
<sl-card class="card">
  <img slot="image" src={image_src} alt="" />
  <strong>{title}</strong>
  <p>{body}</p>
</sl-card>
```

### sl_select.lustre
Select dropdown using `{#each}` for options:
```html
<sl-select label={label} value={selected} @sl-change={on_change}>
  {#each options as opt, idx}
    <sl-option value={opt.value}>{opt.label}</sl-option>
  {/each}
</sl-select>
```

## Running the Example

1. Generate Gleam from templates:
   ```bash
   cd ../..  # Go to project root
   just run
   ```

2. Build and run:
   ```bash
   cd examples/05_shoelace
   gleam deps download
   gleam run -m lustre/dev start
   ```

3. Open http://localhost:1234 in your browser

## Key Files

- `src/types.gleam` - Custom types used by components
- `src/components/sl_button.lustre` - Button with variants
- `src/components/sl_input.lustre` - Input with @sl-input
- `src/components/sl_checkbox.lustre` - Checkbox with boolean attr
- `src/components/sl_dialog.lustre` - Dialog with @sl-hide
- `src/components/sl_card.lustre` - Card with image slot
- `src/components/sl_select.lustre` - Select with {#each}
- `src/app.gleam` - Main app demonstrating all components and decoders

## Exercises

1. Add an `<sl-alert>` component with different variants (primary, success, warning, danger)
2. Create an `<sl-tooltip>` wrapper component for adding tooltips to elements
3. Add an `<sl-switch>` component as an alternative to checkbox
4. Implement an `<sl-tab-group>` with multiple tabs

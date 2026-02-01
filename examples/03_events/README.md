# Example 03: Events

## Concepts

This example demonstrates event handling in Lustre templates, covering the two fundamental patterns for connecting user interactions to your application's message system.

## Prerequisites

Complete Examples 01 and 02 first to understand basic template syntax and attributes.

## The Two Event Handler Patterns

### Pattern 1: Function Reference - `@event={handler}`

Use this pattern when Lustre needs to extract data from the event and pass it to your handler.

```html
<input @input={on_change} />
```

Generates:
```gleam
html.input([event.on_input(on_change)], [])
```

**When to use:**
- `@input` - Lustre extracts the input value
- `@change` - Lustre extracts the changed value
- When your handler signature is `fn(String) -> Msg`

### Pattern 2: Function Call - `@event={handler()}`

Use this pattern when you don't need any event data - you just want to trigger a message.

```html
<button @click={on_click()}>Click me</button>
```

Generates:
```gleam
html.button([event.on_click(on_click())], [html.text("Click me")])
```

**When to use:**
- `@click` - No event data needed
- `@focus` / `@blur` - Just need to know focus changed
- When your handler signature is `fn() -> Msg`

## Event Handler Reference

| Event | Lustre Function | Typical Pattern | Use Case |
|-------|-----------------|-----------------|----------|
| `@click` | `event.on_click()` | Function call | Button clicks, toggles |
| `@input` | `event.on_input()` | Function reference | Text input changes |
| `@change` | `event.on_change()` | Function reference | Select/checkbox changes |
| `@submit` | `event.on_submit()` | Function reference* | Form submission with data |
| `@focus` | `event.on_focus()` | Function call | Input focus tracking |
| `@blur` | `event.on_blur()` | Function call | Input blur tracking |
| `@keydown` | `event.on_keydown()` | Either | Keyboard shortcuts |
| `@custom` | `event.on("custom", ...)` | Function reference | Custom events |

*Note: `@submit` in Lustre expects a handler of type `fn(List(#(String, String))) -> msg` that receives form data. For simple "form submitted" notifications without form data, use `@click` on the submit button instead.

## Components in This Example

### counter.lustre - Function Call Pattern

Demonstrates click events that don't need event data:

```html
<button @click={on_increment()}>+</button>
<button @click={on_decrement()}>-</button>
```

The handler functions return messages directly: `fn() -> msg`

### search_input.lustre - Function Reference Pattern

Demonstrates input events that need the input value:

```html
<input @input={on_change} />
```

The handler receives the input value: `fn(String) -> msg`

### form.lustre - Multiple Event Types

Combines both patterns in a single component:
- `@input={on_input}` - Function reference for input value
- `@click={on_click()}` - Function call for button click
- `@focus={on_focus()}` - Function call for focus tracking
- `@blur={on_blur()}` - Function call for blur tracking

## Running the Example

1. Generate Gleam from templates:
   ```bash
   cd ../..  # Go to project root
   just run
   ```

2. Build and run:
   ```bash
   cd examples/03_events
   gleam deps download
   gleam run -m lustre/dev start
   ```

3. Open http://localhost:1234 in your browser

## Key Files

- `src/components/counter.lustre` - Function call pattern with @click
- `src/components/search_input.lustre` - Function reference pattern with @input
- `src/components/form.lustre` - Multiple events combining both patterns
- `src/app.gleam` - Main app demonstrating all components

## Exercises

1. Add a `@keydown` handler to the search input that clears the query on Escape
2. Create a button that tracks mouse enter/leave with `@mouseenter` and `@mouseleave`
3. Add a reset button to the counter using the function call pattern

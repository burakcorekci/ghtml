# Task 003: Create Events Example

## Description

Create `examples/03_events/` demonstrating both event handler patterns: function reference (`@event={handler}`) and function call (`@event={handler()}`).

## Dependencies

- 001: Rename simple example (directory structure established)

## Success Criteria

1. Example project created at `examples/03_events/`
2. Templates demonstrate both handler patterns clearly
3. README explains when to use each pattern
4. Interactive counter and search demonstrate both patterns

## Implementation Steps

### 1. Create Project Structure

```bash
mkdir -p examples/03_events/src/components
mkdir -p examples/03_events/assets
```

### 2. Create gleam.toml

```toml
name = "example_03_events"
version = "0.1.0"
target = "javascript"

[dependencies]
lustre = "~> 5.0"

[dev-dependencies]
lustre_dev_tools = "~> 2.0"

[tools.lustre.html]
title = "Events Example"
stylesheets = [{ href = "/styles.css" }]
```

### 3. Create Components

#### counter.lustre - Pattern 2: Function Call
```html
@import(gleam/int)

@params(
  count: Int,
  on_increment: fn() -> msg,
  on_decrement: fn() -> msg,
)

<div class="counter">
  <button class="btn" @click={on_decrement()}>-</button>
  <span class="count">{int.to_string(count)}</span>
  <button class="btn" @click={on_increment()}>+</button>
</div>
```

#### search_input.lustre - Pattern 1: Function Reference
```html
@params(
  query: String,
  on_change: fn(String) -> msg,
)

<div class="search">
  <input
    type="search"
    class="input"
    value={query}
    placeholder="Search..."
    @input={on_change}
  />
</div>
```

#### form.lustre - Multiple Event Types
```html
@params(
  value: String,
  on_input: fn(String) -> msg,
  on_submit: fn() -> msg,
  on_focus: fn() -> msg,
  on_blur: fn() -> msg,
)

<form class="form" @submit={on_submit()}>
  <input
    type="text"
    class="input"
    value={value}
    @input={on_input}
    @focus={on_focus()}
    @blur={on_blur()}
  />
  <button type="submit" class="btn">Submit</button>
</form>
```

### 4. Create Main App

```gleam
import lustre
import lustre/element.{type Element}
import lustre/element/html
import components/counter
import components/search_input

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Model {
  Model(count: Int, query: String)
}

fn init(_flags) -> Model {
  Model(count: 0, query: "")
}

type Msg {
  Increment
  Decrement
  UpdateQuery(String)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    Increment -> Model(..model, count: model.count + 1)
    Decrement -> Model(..model, count: model.count - 1)
    UpdateQuery(q) -> Model(..model, query: q)
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.h2([], [element.text("Pattern 2: Function Call (@click={handler()})")]),
    counter.render(model.count, Increment, Decrement),

    html.h2([], [element.text("Pattern 1: Function Reference (@input={handler})")]),
    search_input.render(model.query, UpdateQuery),
    html.p([], [element.text("You typed: " <> model.query)]),
  ])
}
```

### 5. Create README

Explain the two patterns:

**Pattern 1: Function Reference** - `@event={handler}`
- Lustre extracts the event value and passes it to handler
- Use for: `@input`, `@change` where you need the value
- Handler signature: `fn(String) -> Msg`

**Pattern 2: Function Call** - `@event={handler()}`
- You invoke the function directly
- Use for: `@click`, `@submit` where you don't need event data
- Handler signature: `fn() -> Msg`

## Event Handler Reference

| Event | Lustre Function | Typical Pattern |
|-------|-----------------|-----------------|
| @click | `event.on_click()` | Function call |
| @input | `event.on_input()` | Function reference |
| @change | `event.on_change()` | Function reference |
| @submit | `event.on_submit()` | Function call |
| @blur | `event.on_blur()` | Function call |
| @focus | `event.on_focus()` | Function call |
| @keydown | `event.on_keydown()` | Either |
| @custom | `event.on("custom", ...)` | Function reference |

## Verification Checklist

- [ ] Counter increments and decrements on click
- [ ] Search input updates model on typing
- [ ] Form demonstrates submit, focus, blur events
- [ ] README clearly explains both patterns
- [ ] Generated code uses correct event functions

## Files to Create

- `examples/03_events/gleam.toml`
- `examples/03_events/README.md`
- `examples/03_events/assets/styles.css`
- `examples/03_events/src/app.gleam`
- `examples/03_events/src/components/counter.lustre`
- `examples/03_events/src/components/search_input.lustre`
- `examples/03_events/src/components/form.lustre`

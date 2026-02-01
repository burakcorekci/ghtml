# Example 04: Control Flow

## Concepts

This example demonstrates the three control flow constructs in Lustre templates: conditional rendering with `{#if}`, list iteration with `{#each}`, and pattern matching with `{#case}`.

## Prerequisites

Complete Examples 01-03 first to understand basic template syntax, attributes, and events.

## Control Flow Constructs

### `{#if condition}...{:else}...{/if}` - Conditional Rendering

Renders content based on a boolean condition. The `{:else}` branch is optional.

**Template:**
```html
{#if is_admin}
  <span class="admin">Admin</span>
{:else}
  <span class="member">Member</span>
{/if}
```

**Generated Gleam:**
```gleam
case is_admin {
  True -> html.span([attribute.class("admin")], [html.text("Admin")])
  False -> html.span([attribute.class("member")], [html.text("Member")])
}
```

**Without else:**
```html
{#if show_warning}
  <p class="warning">{message}</p>
{/if}
```

Generates `element.none()` for the false case when there's no else branch.

### `{#each collection as item, index}...{/each}` - List Iteration

Iterates over a list, rendering content for each item. The index parameter is optional.

**Template:**
```html
{#each items as item, index}
  <li class="item">
    <span class="index">{int.to_string(index)}.</span>
    <span class="name">{item.name}</span>
  </li>
{/each}
```

**Generated Gleam:**
```gleam
element.keyed(
  html.fragment,
  list.index_map(items, fn(item, index) {
    #(
      item.id,  // Uses first field as key
      html.li([attribute.class("item")], [
        html.span([attribute.class("index")], [html.text(int.to_string(index) <> ".")]),
        html.span([attribute.class("name")], [html.text(item.name)]),
      ])
    )
  })
)
```

**Notes:**
- Uses `keyed()` for Lustre's virtual DOM performance optimization
- The index is 0-based
- Index parameter is optional: `{#each items as item}` works too

### `{#case expr}{:Pattern}...{/case}` - Pattern Matching

Pattern matches on expressions, typically custom types. Supports bindings in patterns.

**Template:**
```html
{#case status}
  {:Online}
    <span class="online">Online</span>
  {:Away(reason)}
    <span class="away">Away: {reason}</span>
  {:Offline}
    <span class="offline">Offline</span>
{/case}
```

**Generated Gleam:**
```gleam
case status {
  Online -> html.span([attribute.class("online")], [html.text("Online")])
  Away(reason) -> html.span([attribute.class("away")], [html.text("Away: " <> reason)])
  Offline -> html.span([attribute.class("offline")], [html.text("Offline")])
}
```

**Notes:**
- Patterns can include variable bindings like `{:Away(reason)}`
- Use the bound variables in the branch content

## Components in This Example

### user_badge.lustre - If/Else

Simple conditional rendering based on admin status.

### if_without_else.lustre - If Without Else

Shows how omitting the else branch renders nothing when false.

### item_list.lustre - Each with Index

Iterates over a list of items, displaying each with its index.

### status_display.lustre - Case Pattern Matching

Matches on a Status type with three variants, including one with a binding.

### todo_item.lustre - Combined Example

A todo item component that uses:
- `{#if}` to show strikethrough for completed items
- `{#case}` to display priority indicators
- Event handlers for toggle and delete actions

## Running the Example

1. Generate Gleam from templates:
   ```bash
   cd ../..  # Go to project root
   just run
   ```

2. Build and run:
   ```bash
   cd examples/04_control_flow
   gleam deps download
   gleam run -m lustre/dev start
   ```

3. Open http://localhost:1234 in your browser

## Key Files

- `src/types.gleam` - Custom types used in the example
- `src/components/user_badge.lustre` - If/else example
- `src/components/if_without_else.lustre` - If without else
- `src/components/item_list.lustre` - Each with index
- `src/components/status_display.lustre` - Case pattern matching
- `src/components/todo_item.lustre` - Combined control flow
- `src/app.gleam` - Main app demonstrating all components

## Exercises

1. Add a filter to the todo list using `{#if}` to show only incomplete items
2. Add a "priority" filter using `{#case}` to show items of a specific priority
3. Create a nested `{#each}` to render a table with rows and columns
4. Add an `{:else if condition}` pattern (hint: you can nest `{#if}` blocks)

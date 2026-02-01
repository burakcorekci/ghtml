# Task 004: Create Control Flow Example

## Description

Create `examples/04_control_flow/` demonstrating all control flow constructs: `{#if}`, `{#each}`, and `{#case}`.

## Dependencies

- 001: Rename simple example (directory structure established)

## Success Criteria

1. Example project created at `examples/04_control_flow/`
2. Templates demonstrate if/else, each with index, and case pattern matching
3. README explains each construct with clear examples
4. Todo list app shows all constructs working together

## Implementation Steps

### 1. Create Project Structure

```bash
mkdir -p examples/04_control_flow/src/components
mkdir -p examples/04_control_flow/assets
```

### 2. Create gleam.toml

```toml
name = "example_04_control_flow"
version = "0.1.0"
target = "javascript"

[dependencies]
lustre = "~> 5.0"

[dev-dependencies]
lustre_dev_tools = "~> 2.0"

[tools.lustre.html]
title = "Control Flow Example"
stylesheets = [{ href = "/styles.css" }]
```

### 3. Create Components

#### user_badge.lustre - If/Else
```html
@params(is_admin: Bool)

<span class="badge">
  {#if is_admin}
    <span class="admin">Admin</span>
  {:else}
    <span class="member">Member</span>
  {/if}
</span>
```

#### if_without_else.lustre - If without Else
```html
@params(show_warning: Bool, message: String)

<div class="notification">
  {#if show_warning}
    <p class="warning">{message}</p>
  {/if}
</div>
```

#### item_list.lustre - Each with Index
```html
@import(gleam/int)
@import(app/types.{type Item})

@params(items: List(Item))

<ul class="item-list">
  {#each items as item, index}
    <li class="item">
      <span class="index">{int.to_string(index)}.</span>
      <span class="name">{item.name}</span>
    </li>
  {/each}
</ul>
```

#### status_display.lustre - Case Pattern Matching
```html
@import(app/types.{type Status, Online, Away, Offline})

@params(status: Status)

<div class="status">
  {#case status}
    {:Online}
      <span class="online">Online</span>
    {:Away(reason)}
      <span class="away">Away: {reason}</span>
    {:Offline}
      <span class="offline">Offline</span>
  {/case}
</div>
```

#### todo_item.lustre - Combined Example
```html
@import(app/types.{type Todo, type Priority, High, Medium, Low})

@params(
  todo: Todo,
  on_toggle: fn() -> msg,
  on_delete: fn() -> msg,
)

<div class="todo-item">
  <input
    type="checkbox"
    checked
    @change={on_toggle()}
  />

  <span class="text">
    {#if todo.completed}
      <s>{todo.text}</s>
    {:else}
      {todo.text}
    {/if}
  </span>

  {#case todo.priority}
    {:High}
      <span class="priority high">!</span>
    {:Medium}
      <span class="priority medium">-</span>
    {:Low}
      <span class="priority low">.</span>
  {/case}

  <button class="delete" @click={on_delete()}>x</button>
</div>
```

### 4. Create Types Module

```gleam
// src/types.gleam
pub type Item {
  Item(id: String, name: String)
}

pub type Status {
  Online
  Away(reason: String)
  Offline
}

pub type Priority {
  High
  Medium
  Low
}

pub type Todo {
  Todo(id: String, text: String, completed: Bool, priority: Priority)
}
```

### 5. Create Main App

A todo list application that demonstrates:
- Filtering with `{#if}`
- List rendering with `{#each}`
- Priority display with `{#case}`

### 6. Create README

Explain each construct:

**`{#if condition}...{:else}...{/if}`**
- Generates: `case condition { True -> ... False -> ... }`
- Else is optional (generates `none()` if omitted)

**`{#each collection as item, index}...{/each}`**
- Generates: `keyed(list.index_map(collection, fn(item, index) { ... }))`
- Index is optional
- Uses `keyed()` for Lustre performance

**`{#case expr}{:Pattern}...{/case}`**
- Generates: `case expr { Pattern -> ... }`
- Supports pattern matching with bindings

## Verification Checklist

- [ ] If/else shows correct branch based on condition
- [ ] If without else renders nothing when false
- [ ] Each renders list with correct indices
- [ ] Case matches patterns correctly
- [ ] Combined todo example works interactively
- [ ] README explains all constructs clearly

## Files to Create

- `examples/04_control_flow/gleam.toml`
- `examples/04_control_flow/README.md`
- `examples/04_control_flow/assets/styles.css`
- `examples/04_control_flow/src/app.gleam`
- `examples/04_control_flow/src/types.gleam`
- `examples/04_control_flow/src/components/user_badge.lustre`
- `examples/04_control_flow/src/components/if_without_else.lustre`
- `examples/04_control_flow/src/components/item_list.lustre`
- `examples/04_control_flow/src/components/status_display.lustre`
- `examples/04_control_flow/src/components/todo_item.lustre`

# lustre_template_gen

[![test](https://github.com/burakcorekci/lustre_template_gen/actions/workflows/test.yml/badge.svg)](https://github.com/burakcorekci/lustre_template_gen/actions/workflows/test.yml)
[![Package Version](https://img.shields.io/hexpm/v/lustre_template_gen)](https://hex.pm/packages/lustre_template_gen)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/lustre_template_gen/)

A Gleam preprocessor that converts `.lustre` template files into Gleam modules with Lustre `Element(msg)` render functions.

## Installation

```sh
gleam add lustre_template_gen@1
```

## Usage

```bash
gleam run -m lustre_template_gen              # Generate all (skips unchanged)
gleam run -m lustre_template_gen -- force     # Force regenerate all
gleam run -m lustre_template_gen -- watch     # Watch mode
gleam run -m lustre_template_gen -- clean     # Remove orphans only
```

## Template Syntax

Templates use a Svelte/Marko-inspired syntax. Place `.lustre` files anywhere in `src/` and they generate corresponding `.gleam` files.

### Metadata
```html
@import(gleam/int)
@import(app/models.{type User})

@params(user: User, count: Int)
```

### Interpolation
```html
<p>{user.name} has {int.to_string(count)} items</p>
<p>Use {{ and }} for literal braces</p>
```

### Control Flow
```html
{#if show_email}
  <input value={user.email} />
{:else}
  <span>Hidden</span>
{/if}

{#each posts as post, i}
  <li>{post.title}</li>
{/each}

{#case user.role}
  {:Admin}
    <span>Admin</span>
  {:Member(since)}
    <span>Member since {int.to_string(since)}</span>
{/case}
```

### Events
```html
<button @click={on_save()}>Save</button>
<input @input={on_change} />
```

## Example

**Input:** `src/components/card.lustre`
```html
@import(gleam/int)
@params(name: String, count: Int)

<div class="card">
  <h1>{name}</h1>
  <p>{int.to_string(count)} items</p>
</div>
```

**Output:** `src/components/card.gleam`
```gleam
// @generated from card.lustre
// @hash abc123...
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute

pub fn render(name: String, count: Int) -> Element(msg) {
  html.div([attribute.class("card")], [
    html.h1([], [text(name)]),
    html.p([], [text(int.to_string(count) <> " items")]),
  ])
}
```

## Features

- **Hash-based caching**: Only regenerates changed templates
- **Orphan cleanup**: Removes generated files when source is deleted
- **Watch mode**: Auto-regenerates on file changes
- **Custom elements**: Tags with hyphens become `element("tag-name", ...)` calls
- **Smart imports**: Only imports modules that are used

## Development

```sh
gleam build  # Build the project
gleam test   # Run the tests
```

Further documentation at <https://hexdocs.pm/lustre_template_gen>.

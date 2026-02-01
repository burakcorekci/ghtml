# Task 007: Create Tailwind Example

## Description

Create `examples/07_tailwind/` demonstrating Tailwind CSS utility-first styling in templates.

## Dependencies

- 001: Rename simple example (directory structure established)

## Success Criteria

1. Example project created at `examples/07_tailwind/`
2. Tailwind Play CDN loads correctly
3. Templates use Tailwind utility classes
4. README explains Tailwind integration patterns

## Implementation Steps

### 1. Create Project Structure

```bash
mkdir -p examples/07_tailwind/src/components
mkdir -p examples/07_tailwind/assets
```

### 2. Create gleam.toml with Tailwind Play CDN

```toml
name = "example_07_tailwind"
version = "0.1.0"
target = "javascript"

[dependencies]
lustre = "~> 5.0"

[dev-dependencies]
lustre_dev_tools = "~> 2.0"

[tools.lustre.html]
title = "Tailwind Example"
scripts = [
  { src = "https://cdn.tailwindcss.com" }
]
```

### 3. Create Components

#### card.lustre
```html
@params(
  title: String,
  body: String,
  image_url: String,
)

<div class="max-w-sm rounded-lg overflow-hidden shadow-lg bg-white">
  <img class="w-full h-48 object-cover" src={image_url} alt="" />
  <div class="px-6 py-4">
    <h3 class="font-bold text-xl mb-2 text-gray-800">{title}</h3>
    <p class="text-gray-600 text-base">{body}</p>
  </div>
</div>
```

#### button.lustre
```html
@params(
  label: String,
  variant: String,
  on_click: fn() -> msg,
)

<button
  class="px-4 py-2 rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2"
  @click={on_click()}
>
  {label}
</button>
```

Note: Dynamic class variants would need to be handled in the app code, as Tailwind Play CDN can't detect dynamically built class names.

#### button_primary.lustre
```html
@params(
  label: String,
  on_click: fn() -> msg,
)

<button
  class="px-4 py-2 rounded-md font-medium bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2"
  @click={on_click()}
>
  {label}
</button>
```

#### button_secondary.lustre
```html
@params(
  label: String,
  on_click: fn() -> msg,
)

<button
  class="px-4 py-2 rounded-md font-medium bg-gray-200 text-gray-800 hover:bg-gray-300 focus:ring-gray-500 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2"
  @click={on_click()}
>
  {label}
</button>
```

#### navbar.lustre
```html
@import(app/types.{type NavItem})

@params(
  brand: String,
  items: List(NavItem),
)

<nav class="bg-gray-800 shadow-lg">
  <div class="max-w-7xl mx-auto px-4">
    <div class="flex justify-between h-16">
      <div class="flex items-center">
        <span class="text-white font-bold text-xl">{brand}</span>
      </div>
      <div class="flex items-center space-x-4">
        {#each items as item, _}
          <a
            href={item.href}
            class="text-gray-300 hover:text-white px-3 py-2 rounded-md text-sm font-medium transition-colors"
          >
            {item.label}
          </a>
        {/each}
      </div>
    </div>
  </div>
</nav>
```

#### alert.lustre
```html
@params(
  message: String,
  variant: String,
)

<div class="rounded-md p-4 mb-4">
  <div class="flex">
    <div class="ml-3">
      <p class="text-sm font-medium">{message}</p>
    </div>
  </div>
</div>
```

#### alert_success.lustre
```html
@params(message: String)

<div class="rounded-md bg-green-50 p-4 mb-4">
  <div class="flex">
    <div class="ml-3">
      <p class="text-sm font-medium text-green-800">{message}</p>
    </div>
  </div>
</div>
```

#### alert_error.lustre
```html
@params(message: String)

<div class="rounded-md bg-red-50 p-4 mb-4">
  <div class="flex">
    <div class="ml-3">
      <p class="text-sm font-medium text-red-800">{message}</p>
    </div>
  </div>
</div>
```

#### grid_layout.lustre
```html
@params(children_count: Int)

<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6">
  <!-- Children would be passed as slots in a real app -->
</div>
```

### 4. Create Types Module

```gleam
// src/types.gleam
pub type NavItem {
  NavItem(label: String, href: String)
}
```

### 5. Create Main App

Demonstrate:
- Cards with image and content
- Button variants
- Navigation bar
- Alert messages
- Responsive grid layout

### 6. Create README

Explain:

**Tailwind Play CDN**
- Quick setup for prototyping
- Add `<script src="https://cdn.tailwindcss.com">` via gleam.toml

**Using Utility Classes**
```html
<div class="bg-white rounded-lg shadow-md p-6">
```
- Classes passed through unchanged as `attribute.class("...")`
- Tailwind scans HTML for classes and generates CSS

**Responsive Design**
```html
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
```
- Prefix with breakpoint: `md:`, `lg:`, `xl:`
- Mobile-first approach

**State Variants**
```html
<button class="bg-blue-500 hover:bg-blue-700 focus:ring-2">
```
- `hover:`, `focus:`, `active:`, `disabled:`

**Dynamic Classes Caveat**
- Tailwind Play CDN can't detect dynamically built class names
- Solution: Create separate components for each variant
- Or use safelist in production Tailwind config

**Production Setup**
For production, install Tailwind properly:
```bash
npm install -D tailwindcss
npx tailwindcss init
```

## Verification Checklist

- [ ] Tailwind CDN loads
- [ ] Cards render with shadows and rounded corners
- [ ] Buttons have hover effects
- [ ] Navigation is responsive
- [ ] Grid layout adapts to screen size
- [ ] Alerts show different colors
- [ ] README explains Tailwind patterns

## Files to Create

- `examples/07_tailwind/gleam.toml`
- `examples/07_tailwind/README.md`
- `examples/07_tailwind/assets/styles.css` (minimal, Tailwind handles most)
- `examples/07_tailwind/src/app.gleam`
- `examples/07_tailwind/src/types.gleam`
- `examples/07_tailwind/src/components/card.lustre`
- `examples/07_tailwind/src/components/button_primary.lustre`
- `examples/07_tailwind/src/components/button_secondary.lustre`
- `examples/07_tailwind/src/components/navbar.lustre`
- `examples/07_tailwind/src/components/alert_success.lustre`
- `examples/07_tailwind/src/components/alert_error.lustre`

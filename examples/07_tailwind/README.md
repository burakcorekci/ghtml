# Example 07: Tailwind CSS

## Concepts

This example demonstrates how to use [Tailwind CSS](https://tailwindcss.com/) utility-first styling with Lustre templates. It shows that Tailwind classes work seamlessly in `.lustre` files since they're passed through as standard `class` attributes.

## Prerequisites

Complete Examples 01-04 first to understand basic template syntax, attributes, events, and control flow.

## Tailwind Play CDN Setup

For quick prototyping, we use the Tailwind Play CDN. Add it to your `gleam.toml`:

```toml
[tools.lustre.html]
title = "Tailwind Example"
scripts = [
  { src = "https://cdn.tailwindcss.com" }
]
```

The CDN script scans your HTML for Tailwind class names and generates the CSS at runtime. This is perfect for development and prototyping but not recommended for production.

## Using Utility Classes

Tailwind utility classes work exactly like any other class in templates:

```html
<div class="bg-white rounded-lg shadow-md p-6">
  <h2 class="text-xl font-bold text-gray-800">{title}</h2>
  <p class="text-gray-600 mt-2">{body}</p>
</div>
```

The generator outputs:

```gleam
html.div([attribute.class("bg-white rounded-lg shadow-md p-6")], [
  html.h2([attribute.class("text-xl font-bold text-gray-800")], [text(title)]),
  html.p([attribute.class("text-gray-600 mt-2")], [text(body)]),
])
```

Classes are passed through unchanged. Tailwind's JIT compiler (or Play CDN) handles generating the actual CSS.

## Responsive Design

Tailwind uses a mobile-first approach with responsive prefixes:

```html
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <!-- Cards here -->
</div>
```

| Prefix | Breakpoint | Meaning |
|--------|------------|---------|
| (none) | 0px+ | Mobile and up (default) |
| `sm:` | 640px+ | Small screens |
| `md:` | 768px+ | Medium screens |
| `lg:` | 1024px+ | Large screens |
| `xl:` | 1280px+ | Extra large screens |
| `2xl:` | 1536px+ | 2X large screens |

## State Variants

Add interactive states with prefixes:

```html
<button class="bg-blue-600 hover:bg-blue-700 focus:ring-2 focus:ring-blue-500">
  Click me
</button>
```

Common state prefixes:
- `hover:` - Mouse hover
- `focus:` - Keyboard focus
- `active:` - Active/pressed state
- `disabled:` - Disabled state

## Dynamic Classes Caveat

**Important:** Tailwind Play CDN scans your HTML for class names at build time. Dynamically constructed class names won't be detected:

```html
<!-- This WON'T work with Tailwind CDN -->
<div class={"bg-" <> color <> "-500"}>

<!-- This also WON'T work -->
@params(variant: String)
<div class={variant}>
```

### Solution: Separate Components

Create a separate template for each variant:

```html
<!-- button_primary.lustre -->
<button class="bg-blue-600 hover:bg-blue-700 text-white ...">
  {label}
</button>

<!-- button_secondary.lustre -->
<button class="bg-gray-200 hover:bg-gray-300 text-gray-800 ...">
  {label}
</button>
```

This approach:
1. Works with Tailwind's class detection
2. Provides better type safety
3. Makes intent clear at the call site

## Components in This Example

### card.lustre
Responsive card with image, shadow, and rounded corners:
```html
<div class="max-w-sm rounded-lg overflow-hidden shadow-lg bg-white">
  <img class="w-full h-48 object-cover" src={image_url} alt="" />
  <div class="px-6 py-4">
    <h3 class="font-bold text-xl mb-2 text-gray-800">{title}</h3>
    <p class="text-gray-600 text-base">{body}</p>
  </div>
</div>
```

### button_primary.lustre / button_secondary.lustre
Buttons with hover and focus states. Separate templates for each variant:
```html
<button
  class="px-4 py-2 rounded-md font-medium bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2"
  @click={on_click()}
>
  {label}
</button>
```

### navbar.lustre
Responsive navigation with flexbox:
```html
<nav class="bg-gray-800 shadow-lg">
  <div class="max-w-7xl mx-auto px-4">
    <div class="flex justify-between h-16">
      <!-- Brand and nav items -->
    </div>
  </div>
</nav>
```

### alert_success.lustre / alert_error.lustre
Alert components with variant-specific colors:
```html
<div class="rounded-md bg-green-50 p-4 mb-4">
  <p class="text-sm font-medium text-green-800">{message}</p>
</div>
```

## Running the Example

1. Generate Gleam from templates:
   ```bash
   cd ../..  # Go to project root
   just run
   ```

2. Build and run:
   ```bash
   cd examples/07_tailwind
   gleam deps download
   gleam run -m lustre/dev start
   ```

3. Open http://localhost:1234 in your browser

4. Resize the browser to see the responsive grid adapt

## Production Setup

For production, don't use the Play CDN. Install Tailwind properly:

```bash
npm install -D tailwindcss
npx tailwindcss init
```

Create `tailwind.config.js`:
```javascript
module.exports = {
  content: ["./src/**/*.{lustre,gleam,html,js}"],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

Add a build step:
```bash
npx tailwindcss -i ./assets/input.css -o ./priv/static/styles.css
```

This generates only the CSS you actually use, resulting in much smaller file sizes.

## Key Files

- `src/types.gleam` - NavItem type for navbar
- `src/components/card.lustre` - Card with image and content
- `src/components/button_primary.lustre` - Primary button variant
- `src/components/button_secondary.lustre` - Secondary button variant
- `src/components/navbar.lustre` - Navigation bar with links
- `src/components/alert_success.lustre` - Success alert
- `src/components/alert_error.lustre` - Error alert
- `src/app.gleam` - Main app demonstrating all components

## Exercises

1. Add a `button_danger.lustre` variant with red styling
2. Create an `alert_warning.lustre` with yellow/amber colors
3. Add a footer component with responsive columns
4. Create a form component with Tailwind-styled inputs
5. Add dark mode support using `dark:` prefix (requires Tailwind config)

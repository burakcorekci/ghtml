import components/alert_error
import components/alert_success
import components/button_primary
import components/button_secondary
import components/card
import components/navbar
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import types.{NavItem}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Model {
  Model(
    button_clicks: Int,
    show_success: Bool,
    show_error: Bool,
  )
}

fn init(_flags) -> Model {
  Model(
    button_clicks: 0,
    show_success: False,
    show_error: False,
  )
}

type Msg {
  IncrementClicks
  ToggleSuccess
  ToggleError
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    IncrementClicks -> Model(..model, button_clicks: model.button_clicks + 1)
    ToggleSuccess -> Model(..model, show_success: !model.show_success)
    ToggleError -> Model(..model, show_error: !model.show_error)
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("min-h-screen bg-gray-100")], [
    // Navigation bar
    navbar.render("Tailwind + Lustre", [
      NavItem("Home", "#"),
      NavItem("About", "#about"),
      NavItem("Contact", "#contact"),
    ]),
    // Main content
    html.main([attribute.class("max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8")], [
      // Hero section
      html.div([attribute.class("text-center mb-12")], [
        html.h1(
          [attribute.class("text-4xl font-bold text-gray-900 mb-4")],
          [html.text("Tailwind CSS Example")],
        ),
        html.p(
          [attribute.class("text-xl text-gray-600 max-w-2xl mx-auto")],
          [
            html.text(
              "This example demonstrates how to use Tailwind CSS utility classes in Lustre templates. All styling is done with Tailwind utilities.",
            ),
          ],
        ),
      ]),
      // Alerts section
      html.div([attribute.class("mb-8")], [
        html.h2(
          [attribute.class("text-2xl font-semibold text-gray-800 mb-4")],
          [html.text("Alerts")],
        ),
        html.p(
          [attribute.class("text-gray-600 mb-4")],
          [
            html.text(
              "Tailwind makes it easy to create variant components. Each alert variant is a separate template with its own color scheme.",
            ),
          ],
        ),
        case model.show_success {
          True -> alert_success.render("Operation completed successfully!")
          False -> html.text("")
        },
        case model.show_error {
          True -> alert_error.render("An error occurred. Please try again.")
          False -> html.text("")
        },
        html.div([attribute.class("flex gap-2")], [
          button_primary.render("Toggle Success", fn() { ToggleSuccess }),
          button_secondary.render("Toggle Error", fn() { ToggleError }),
        ]),
      ]),
      // Buttons section
      html.div([attribute.class("mb-8")], [
        html.h2(
          [attribute.class("text-2xl font-semibold text-gray-800 mb-4")],
          [html.text("Buttons")],
        ),
        html.p(
          [attribute.class("text-gray-600 mb-4")],
          [
            html.text(
              "Buttons with Tailwind utilities for colors, spacing, hover states, and focus rings. Click count: ",
            ),
            html.span(
              [attribute.class("font-bold text-blue-600")],
              [html.text(int_to_string(model.button_clicks))],
            ),
          ],
        ),
        html.div([attribute.class("flex gap-4 flex-wrap")], [
          button_primary.render("Primary Action", fn() { IncrementClicks }),
          button_secondary.render("Secondary Action", fn() { IncrementClicks }),
        ]),
      ]),
      // Cards section with responsive grid
      html.div([attribute.class("mb-8")], [
        html.h2(
          [attribute.class("text-2xl font-semibold text-gray-800 mb-4")],
          [html.text("Responsive Card Grid")],
        ),
        html.p(
          [attribute.class("text-gray-600 mb-4")],
          [
            html.text(
              "Cards in a responsive grid that adapts from 1 column on mobile to 3 columns on large screens. Resize your browser to see it in action.",
            ),
          ],
        ),
        html.div(
          [attribute.class("grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6")],
          [
            card.render(
              "Utility-First CSS",
              "Tailwind provides low-level utility classes that let you build completely custom designs without leaving your HTML.",
              "https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=400&h=200&fit=crop",
            ),
            card.render(
              "Responsive Design",
              "Use responsive modifiers like md: and lg: to build responsive interfaces. Mobile-first approach out of the box.",
              "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=400&h=200&fit=crop",
            ),
            card.render(
              "State Variants",
              "Add hover:, focus:, and active: prefixes to any utility for interactive states. No custom CSS needed.",
              "https://images.unsplash.com/photo-1551650975-87deedd944c3?w=400&h=200&fit=crop",
            ),
          ],
        ),
      ]),
      // Dynamic Classes Caveat section
      html.div(
        [attribute.class("bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-8")],
        [
          html.h3(
            [attribute.class("text-lg font-medium text-yellow-800 mb-2")],
            [html.text("Dynamic Classes Note")],
          ),
          html.p(
            [attribute.class("text-yellow-700")],
            [
              html.text(
                "Tailwind Play CDN scans your HTML for class names at runtime. Dynamically constructed class names (like 'bg-' <> color) won't be detected. Create separate components for each variant instead.",
              ),
            ],
          ),
        ],
      ),
    ]),
  ])
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> {
      let quotient = n / 10
      let remainder = n % 10
      int_to_string(quotient) <> int_to_string(remainder)
    }
  }
}

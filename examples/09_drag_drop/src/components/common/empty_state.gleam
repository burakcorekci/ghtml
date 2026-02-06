// @generated from empty_state.ghtml
// @hash 3f460030b20cd1397ba99d9fcf9df47ac515b2a9880f4f021b6143c7fad0ad2e
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text, element}
import lustre/element/html
import lustre/attribute
import lustre/event

pub fn render(icon: String, title: String, description: String, action_label: String, on_action: fn() -> msg) -> Element(msg) {
  html.div([attribute.class("flex flex-col items-center justify-center py-12 px-4 text-center")], [html.div([attribute.class("text-6xl mb-4")], [text(icon)]), html.h3([attribute.class("text-lg font-medium text-gray-900 mb-2")], [text(title)]), html.p([attribute.class("text-gray-500 mb-6 max-w-sm")], [text(description)]), element("sl-button", [attribute.attribute("variant", "primary"), event.on_click(on_action())], [text(action_label)])])
}

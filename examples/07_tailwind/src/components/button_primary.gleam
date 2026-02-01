// @generated from button_primary.lustre
// @hash f2da601302a56a405cdf54224acee5b8fb2f4d894919c8eb8db7aae2d83dfec1
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute
import lustre/event

pub fn render(label: String, on_click: fn() -> msg) -> Element(msg) {
  html.button([attribute.class("px-4 py-2 rounded-md font-medium bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2"), event.on_click(on_click())], [text(label)])
}

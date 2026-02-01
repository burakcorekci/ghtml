// @generated from button_secondary.lustre
// @hash b1b13da86d82c32ed82ca1a50f6e4203a97e274888ea7554cef005ff40bd948f
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute
import lustre/event

pub fn render(label: String, on_click: fn() -> msg) -> Element(msg) {
  html.button([attribute.class("px-4 py-2 rounded-md font-medium bg-gray-200 text-gray-800 hover:bg-gray-300 focus:ring-gray-500 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2"), event.on_click(on_click())], [text(label)])
}

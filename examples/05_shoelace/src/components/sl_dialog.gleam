// @generated from sl_dialog.lustre
// @hash 023e900cd04aabfbc74b8c58eec7784e7d3499679368a304157ca82287f7649b
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text, element}
import lustre/element/html
import lustre/attribute
import lustre/event
import gleam/dynamic/decode

pub fn render(title: String, is_open: Bool, on_close_decoder: decode.Decoder(msg), on_close_click: fn() -> msg) -> Element(msg) {
  case is_open { True -> element("sl-dialog", [attribute.attribute("label", title), attribute.attribute("open", ""), event.on("sl-hide", on_close_decoder)], [html.p([], [text("This is a Shoelace dialog component.")]), element("sl-button", [attribute.attribute("slot", "footer"), attribute.attribute("variant", "primary"), event.on_click(on_close_click())], [text("\n Close\n ")])]) False -> element("sl-dialog", [attribute.attribute("label", title), event.on("sl-hide", on_close_decoder)], [html.p([], [text("This is a Shoelace dialog component.")]), element("sl-button", [attribute.attribute("slot", "footer"), attribute.attribute("variant", "primary"), event.on_click(on_close_click())], [text("\n Close\n ")])]) }
}

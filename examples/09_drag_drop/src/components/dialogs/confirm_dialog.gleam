// @generated from confirm_dialog.ghtml
// @hash 98c5edae67cfc4071f8941f8305b2a921af5e3ac573f4ae10f79edb039c3c916
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text, element}
import lustre/element/html
import lustre/attribute
import lustre/event
import gleam/dynamic/decode

pub fn render(is_open: Bool, title: String, message: String, confirm_label: String, on_confirm: fn() -> msg, on_cancel: fn() -> msg, on_close_decoder: decode.Decoder(msg)) -> Element(msg) {
  case is_open { True -> element("sl-dialog", [attribute.attribute("label", title), attribute.attribute("open", ""), event.on("sl-hide", on_close_decoder)], [html.p([attribute.class("text-gray-600")], [text(message)]), html.div([attribute.attribute("slot", "footer"), attribute.class("flex gap-2 justify-end")], [element("sl-button", [attribute.attribute("variant", "default"), event.on_click(on_cancel())], [text("Cancel")]), element("sl-button", [attribute.attribute("variant", "danger"), event.on_click(on_confirm())], [text(confirm_label)])])]) False -> html.span([], []) }
}

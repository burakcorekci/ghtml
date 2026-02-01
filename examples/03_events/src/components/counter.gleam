// @generated from counter.lustre
// @hash 9884f45a2438d895ae5b962a78117bc425b9100bdbb5c968b3811fe314bcb2ae
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute
import lustre/event
import gleam/int

pub fn render(count: Int, on_increment: fn() -> msg, on_decrement: fn() -> msg) -> Element(msg) {
  html.div([attribute.class("counter")], [html.button([attribute.class("btn"), event.on_click(on_decrement())], [text("-")]), html.span([attribute.class("count")], [text(int.to_string(count))]), html.button([attribute.class("btn"), event.on_click(on_increment())], [text("+")])])
}

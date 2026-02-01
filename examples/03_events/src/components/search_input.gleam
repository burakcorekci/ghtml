// @generated from search_input.lustre
// @hash f13dbe6c046b6dba6877cf5a86d13d30aa4ad9247372f291464bc6ffae940dc9
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element}
import lustre/element/html
import lustre/attribute
import lustre/event

pub fn render(query: String, on_change: fn(String) -> msg) -> Element(msg) {
  html.div([attribute.class("search")], [html.input([attribute.type_("search"), attribute.class("input"), attribute.value(query), attribute.placeholder("Search..."), event.on_input(on_change)])])
}

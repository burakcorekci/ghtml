// @generated from navbar.lustre
// @hash 095442d0816adbc385883b52a17da0b2113e697fbe5769bf4e170c980a597d24
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/element/keyed
import lustre/attribute
import gleam/list
import gleam/int
import types.{type NavItem}

pub fn render(brand: String, items: List(NavItem)) -> Element(msg) {
  html.nav([attribute.class("bg-gray-800 shadow-lg")], [html.div([attribute.class("max-w-7xl mx-auto px-4")], [html.div([attribute.class("flex justify-between h-16")], [html.div([attribute.class("flex items-center")], [html.span([attribute.class("text-white font-bold text-xl")], [text(brand)])]), html.div([attribute.class("flex items-center space-x-4")], [keyed.fragment(list.index_map(items, fn(item, idx) { #(int.to_string(idx), html.a([attribute.href(item.href), attribute.class("text-gray-300 hover:text-white px-3 py-2 rounded-md text-sm font-medium transition-colors")], [text(item.label)])) }))])])])])
}

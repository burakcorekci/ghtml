// @generated from demo_all.lustre
// @hash 77ce431864108ec3a92a7598393f576e829421b8ee4c0b564f182cebed913866
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/element/keyed
import lustre/attribute
import gleam/list
import gleam/int
import types.{type User, type Status, Online, Away, Offline}

pub fn render(user: User, items: List(String), status: Status) -> Element(msg) {
  html.div([attribute.class("dashboard")], [case user.is_admin { True -> html.span([attribute.class("badge")], [text("Admin")]) False -> html.span([attribute.class("badge")], [text("Member")]) }, html.ul([], [keyed.fragment(list.index_map(items, fn(item, i) { #(int.to_string(i), html.li([], [text(int.to_string(i)), text(": "), text(item)])) }))]), case status { Online -> html.span([attribute.class("green")], [text("Online")]) Away(reason) -> html.span([attribute.class("yellow")], [text("Away: "), text(reason)]) Offline -> html.span([attribute.class("gray")], [text("Offline")]) }])
}

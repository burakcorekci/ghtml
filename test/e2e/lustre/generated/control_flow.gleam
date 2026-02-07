// @generated from full.ghtml
// @hash a42bb361efde13b6c904f974200e66415b79dbf4767af620895fe247916318f0
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import e2e/lustre/generated/types.{
  type Status, type User, Active, Inactive, Pending,
}
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/element/keyed

pub fn render(user: User, items: List(String), status: Status) -> Element(msg) {
  html.article([attribute.class("user-card")], [
    case user.is_admin {
      True -> html.span([attribute.class("badge")], [text("Admin")])
      False -> html.span([attribute.class("badge")], [text("User")])
    },
    html.ul([], [
      keyed.fragment(
        list.index_map(items, fn(item, i) {
          #(
            int.to_string(i),
            html.li([], [text(int.to_string(i)), text(": "), text(item)]),
          )
        }),
      ),
    ]),
    case status {
      Active -> html.span([attribute.class("status active")], [text("Active")])
      Inactive ->
        html.span([attribute.class("status inactive")], [text("Inactive")])
      Pending ->
        html.span([attribute.class("status pending")], [text("Pending")])
    },
  ])
}

// @generated from user_badge.lustre
// @hash 0ccec706cd584675c1439e297a00712b0410ffcb4253ab0db7ba3321311b8359
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute

pub fn render(is_admin: Bool) -> Element(msg) {
  html.span([attribute.class("badge")], [case is_admin { True -> html.span([attribute.class("admin")], [text("Admin")]) False -> html.span([attribute.class("member")], [text("Member")]) }])
}

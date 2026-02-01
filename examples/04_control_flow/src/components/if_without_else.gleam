// @generated from if_without_else.lustre
// @hash d448d362a24f775a44cb5e9effe5cfc5e1123d739430c3b2e3ab777a991a91a3
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text, none}
import lustre/element/html
import lustre/attribute

pub fn render(show_warning: Bool, message: String) -> Element(msg) {
  html.div([attribute.class("notification")], [case show_warning { True -> html.p([attribute.class("warning")], [text(message)]) False -> none() }])
}

// @generated from greeting.lustre
// @hash a17d54407872a17835ac16ddc61c6e3a72b64aacb93a6a84560d0ebf8aa5e07c
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/attribute

pub fn render(name: String) -> Element(msg) {
  html.div([attribute.class("greeting")], [html.h1([], [text("Hello, "), text(name), text("!")]), html.p([], [text("Welcome to Lustre with template generation.")])])
}

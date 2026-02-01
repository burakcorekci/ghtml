// @generated from sl_card.lustre
// @hash d0c1bc2482d576e61c2a276299419f431e4b01b0b3ed9ce8e7e17d97cbfdda4e
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text, element}
import lustre/element/html
import lustre/attribute

pub fn render(title: String, body: String, image_src: String) -> Element(msg) {
  element("sl-card", [attribute.class("card")], [html.img([attribute.attribute("slot", "image"), attribute.src(image_src), attribute.alt("")]), html.strong([], [text(title)]), html.p([], [text(body)])])
}

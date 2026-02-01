// @generated from item_list.lustre
// @hash c26869765c2c23f7c2503de1439076dd3ff135ff62ffa7179b740b2ca223c612
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/element/keyed
import lustre/attribute
import gleam/list
import gleam/int
import types.{type Item}

pub fn render(items: List(Item)) -> Element(msg) {
  html.ul([attribute.class("item-list")], [keyed.fragment(list.index_map(items, fn(item, index) { #(int.to_string(index), html.li([attribute.class("item")], [html.span([attribute.class("index")], [text(int.to_string(index)), text(".")]), html.span([attribute.class("name")], [text(item.name)])])) }))])
}

// @generated from md_list.lustre
// @hash e186c1bb4033535422f9b5843ee848d22fef344c34024b01a03cdfbecf765870
// DO NOT EDIT - regenerate with: gleam run -m lustre_template_gen

import lustre/element.{type Element, text, element}
import lustre/element/html
import lustre/element/keyed
import lustre/attribute
import gleam/list
import gleam/int
import types.{type ListItem}

pub fn render(items: List(ListItem)) -> Element(msg) {
  element("md-list", [], [keyed.fragment(list.index_map(items, fn(item, idx) { #(int.to_string(idx), element("md-list-item", [], [html.span([attribute.attribute("slot", "headline")], [text(item.headline)]), html.span([attribute.attribute("slot", "supporting-text")], [text(item.supporting)])])) }))])
}

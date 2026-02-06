// @generated from task_list.ghtml
// @hash ab81b996046fc8f85342091215f7e1b3df721c487ffb854220e7629adcb02a43
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/element/keyed
import lustre/attribute
import lustre/event
import gleam/list
import gleam/int
import gleam/option.{type Option, Some}
import model.{type Task}

pub fn render(tasks: List(Task), selected_task_id: Option(String), on_click: fn(String) -> msg) -> Element(msg) {
  html.div([attribute.class("space-y-3")], [keyed.fragment(list.index_map(tasks, fn(task, idx) { #(int.to_string(idx), html.div([attribute.class("task-item")], [case selected_task_id == Some(task.id) { True -> html.div([attribute.class("ring-2 ring-blue-500 rounded-lg")], [html.div([attribute.class("p-4 bg-blue-50 dark:bg-blue-900/30 rounded-lg")], [html.h3([attribute.class("font-medium dark:text-white")], [text(task.title)]), html.p([attribute.class("text-sm text-gray-600 dark:text-gray-400")], [text(task.description)])])]) False -> html.div([attribute.class("rounded-lg")], [html.div([attribute.class("p-4 bg-white dark:bg-gray-800 border dark:border-gray-700 rounded-lg hover:shadow-md cursor-pointer"), event.on_click(on_click(task.id))], [html.h3([attribute.class("font-medium dark:text-white")], [text(task.title)]), html.p([attribute.class("text-sm text-gray-600 dark:text-gray-400")], [text(task.description)])])]) }])) }))])
}

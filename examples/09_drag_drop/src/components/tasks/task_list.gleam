// @generated from task_list.ghtml
// @hash c851d576ae6b578f8d7601a540b12ea64febd0a1cce928d63436f0073199094e
// DO NOT EDIT - regenerate with: gleam run -m ghtml

import lustre/element.{type Element, text}
import lustre/element/html
import lustre/element/keyed
import lustre/attribute
import lustre/event
import gleam/list
import gleam/int
import gleam/option.{type Option, Some}
import model.{type Task, High, Medium, Low, NoPriority}

pub fn render(tasks: List(Task), selected_task_id: Option(String), on_click: fn(String) -> msg) -> Element(msg) {
  html.div([attribute.class("space-y-3")], [keyed.fragment(list.index_map(tasks, fn(task, idx) { #(int.to_string(idx), html.div([attribute.class("task-item")], [case selected_task_id == Some(task.id) { True -> html.div([attribute.class("ring-2 ring-blue-500 rounded-lg")], [html.div([attribute.class("relative p-4 bg-blue-50 dark:bg-blue-900/30 rounded-lg")], [case task.priority { High -> html.span([attribute.class("absolute top-3 right-3 w-2.5 h-2.5 rounded-full bg-red-500")], []) Medium -> html.span([attribute.class("absolute top-3 right-3 w-2.5 h-2.5 rounded-full bg-orange-500")], []) Low -> html.span([attribute.class("absolute top-3 right-3 w-2.5 h-2.5 rounded-full bg-purple-500")], []) NoPriority -> html.span([], []) }, html.h3([attribute.class("font-medium dark:text-white")], [text(task.title)]), html.p([attribute.class("text-sm text-gray-600 dark:text-gray-400")], [text(task.description)])])]) False -> html.div([attribute.class("rounded-lg")], [html.div([attribute.class("relative p-4 bg-white dark:bg-gray-800 border dark:border-gray-700 rounded-lg hover:shadow-md cursor-pointer"), event.on_click(on_click(task.id))], [case task.priority { High -> html.span([attribute.class("absolute top-3 right-3 w-2.5 h-2.5 rounded-full bg-red-500")], []) Medium -> html.span([attribute.class("absolute top-3 right-3 w-2.5 h-2.5 rounded-full bg-orange-500")], []) Low -> html.span([attribute.class("absolute top-3 right-3 w-2.5 h-2.5 rounded-full bg-purple-500")], []) NoPriority -> html.span([], []) }, html.h3([attribute.class("font-medium dark:text-white")], [text(task.title)]), html.p([attribute.class("text-sm text-gray-600 dark:text-gray-400")], [text(task.description)])])]) }])) }))])
}

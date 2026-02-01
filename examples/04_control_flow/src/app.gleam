import components/if_without_else
import components/item_list
import components/status_display
import components/todo_item
import components/user_badge
import gleam/int
import gleam/list
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import types.{type Item, type Priority, type Status, type Todo}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Model {
  Model(
    // If/Else demo
    is_admin: Bool,
    // If without else demo
    show_warning: Bool,
    // Each demo
    items: List(Item),
    // Case demo
    status: Status,
    // Todo list demo (combines all)
    todos: List(Todo),
    new_todo_text: String,
    new_todo_priority: Priority,
  )
}

fn init(_flags) -> Model {
  Model(
    is_admin: True,
    show_warning: True,
    items: [
      types.Item("1", "Learn Gleam"),
      types.Item("2", "Build with Lustre"),
      types.Item("3", "Master templates"),
    ],
    status: types.Online,
    todos: [
      types.Todo("1", "Read the docs", True, types.Low),
      types.Todo("2", "Try the examples", False, types.Medium),
      types.Todo("3", "Build something", False, types.High),
    ],
    new_todo_text: "",
    new_todo_priority: types.Medium,
  )
}

type Msg {
  // If/Else toggle
  ToggleAdmin
  // If without else toggle
  ToggleWarning
  // Status change
  SetStatus(Status)
  // Todo actions
  ToggleTodo(String)
  DeleteTodo(String)
  UpdateNewTodoText(String)
  SetNewTodoPriority(Priority)
  AddTodo
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    ToggleAdmin -> Model(..model, is_admin: !model.is_admin)
    ToggleWarning -> Model(..model, show_warning: !model.show_warning)
    SetStatus(status) -> Model(..model, status: status)
    ToggleTodo(id) ->
      Model(
        ..model,
        todos: list.map(model.todos, fn(t) {
          case t.id == id {
            True -> types.Todo(..t, completed: !t.completed)
            False -> t
          }
        }),
      )
    DeleteTodo(id) ->
      Model(..model, todos: list.filter(model.todos, fn(t) { t.id != id }))
    UpdateNewTodoText(text) -> Model(..model, new_todo_text: text)
    SetNewTodoPriority(priority) ->
      Model(..model, new_todo_priority: priority)
    AddTodo -> {
      let id = int.to_string(list.length(model.todos) + 1)
      let new_todo =
        types.Todo(id, model.new_todo_text, False, model.new_todo_priority)
      Model(..model, todos: list.append(model.todos, [new_todo]), new_todo_text: "")
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Control Flow Example")]),
    // If/Else Section
    html.div([attribute.class("section")], [
      html.h2([], [html.text("{#if}...{:else}...{/if}")]),
      html.p([], [
        html.text(
          "Conditional rendering based on a boolean expression. The else branch is optional.",
        ),
      ]),
      html.div([attribute.class("demo")], [
        user_badge.render(model.is_admin),
        html.button([attribute.class("btn"), event.on_click(ToggleAdmin)], [
          html.text("Toggle Admin"),
        ]),
      ]),
    ]),
    // If without Else Section
    html.div([attribute.class("section")], [
      html.h2([], [html.text("{#if}...{/if} (without else)")]),
      html.p([], [
        html.text(
          "When the condition is false and there's no else branch, nothing is rendered.",
        ),
      ]),
      html.div([attribute.class("demo")], [
        if_without_else.render(model.show_warning, "This is a warning message!"),
        html.button([attribute.class("btn"), event.on_click(ToggleWarning)], [
          html.text("Toggle Warning"),
        ]),
      ]),
    ]),
    // Each Section
    html.div([attribute.class("section")], [
      html.h2([], [html.text("{#each collection as item, index}...{/each}")]),
      html.p([], [
        html.text(
          "Iterate over a list. The index is optional. Uses keyed() for Lustre performance.",
        ),
      ]),
      html.div([attribute.class("demo")], [item_list.render(model.items)]),
    ]),
    // Case Section
    html.div([attribute.class("section")], [
      html.h2([], [html.text("{#case expr}{:Pattern}...{/case}")]),
      html.p([], [
        html.text(
          "Pattern matching on custom types. Supports bindings in patterns.",
        ),
      ]),
      html.div([attribute.class("demo")], [
        status_display.render(model.status),
        html.div([attribute.class("controls")], [
          html.button(
            [attribute.class("btn"), event.on_click(SetStatus(types.Online))],
            [html.text("Online")],
          ),
          html.button(
            [
              attribute.class("btn"),
              event.on_click(SetStatus(types.Away("lunch break"))),
            ],
            [html.text("Away")],
          ),
          html.button(
            [attribute.class("btn"), event.on_click(SetStatus(types.Offline))],
            [html.text("Offline")],
          ),
        ]),
      ]),
    ]),
    // Combined Todo Section
    html.div([attribute.class("section")], [
      html.h2([], [html.text("Combined Example: Todo List")]),
      html.p([], [
        html.text(
          "This todo list uses all three control flow constructs together.",
        ),
      ]),
      html.div([attribute.class("todo-list")], [
        html.div([attribute.class("add-todo")], [
          html.input([
            attribute.class("input"),
            attribute.placeholder("New todo..."),
            attribute.value(model.new_todo_text),
            event.on_input(UpdateNewTodoText),
          ]),
          html.select([event.on_input(fn(s) { parse_priority(s) })], [
            html.option([attribute.value("low")], "Low"),
            html.option([attribute.value("medium"), attribute.selected(True)], "Medium"),
            html.option([attribute.value("high")], "High"),
          ]),
          html.button([attribute.class("btn"), event.on_click(AddTodo)], [
            html.text("Add"),
          ]),
        ]),
        html.div(
          [attribute.class("items")],
          list.map(model.todos, fn(t) {
            todo_item.render(
              t,
              fn() { ToggleTodo(t.id) },
              fn() { DeleteTodo(t.id) },
            )
          }),
        ),
      ]),
    ]),
  ])
}

fn parse_priority(s: String) -> Msg {
  case s {
    "high" -> SetNewTodoPriority(types.High)
    "low" -> SetNewTodoPriority(types.Low)
    _ -> SetNewTodoPriority(types.Medium)
  }
}

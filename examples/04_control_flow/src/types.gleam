/// Types used across the control flow example components

pub type User {
  User(name: String, is_admin: Bool)
}

pub type Item {
  Item(id: String, name: String)
}

pub type Status {
  Online
  Away(reason: String)
  Offline
}

pub type Priority {
  High
  Medium
  Low
}

pub type Todo {
  Todo(id: String, text: String, completed: Bool, priority: Priority)
}

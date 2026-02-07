//// Types used by pre-generated SSR test modules
//// This mirrors the types expected by control_flow.ghtml

pub type User {
  User(name: String, email: String, is_admin: Bool)
}

pub type Status {
  Active
  Inactive
  Pending
}

pub type Role {
  Admin
  Member(since: Int)
  Guest
}

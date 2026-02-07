//// Common types used in E2E test templates
//// These types are referenced by the template fixtures

/// A sample user type for testing
pub type User {
  User(name: String, email: String, is_admin: Bool, role: Role)
}

/// Role variants for case expression testing
pub type Role {
  Admin
  Member(since: Int)
  Guest
}

/// Status variants for testing
pub type Status {
  Active
  Inactive
  Pending
}

/// Creates a sample user for testing
pub fn sample_user() -> User {
  User(
    name: "Test User",
    email: "test@example.com",
    is_admin: False,
    role: Member(2024),
  )
}

/// Creates an admin user for testing
pub fn admin_user() -> User {
  User(
    name: "Admin User",
    email: "admin@example.com",
    is_admin: True,
    role: Admin,
  )
}

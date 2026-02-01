# Task 009: Add CI Validation for Examples

## Description

Update the project's `check` and `ci` commands to validate that all examples build successfully. This ensures examples don't break as the template generator evolves.

## Dependencies

- 001-008: All examples must exist before adding validation

## Success Criteria

1. `just check` validates all examples build
2. `just ci` includes example validation
3. Failures in any example fail the overall check
4. Clear error messages identify which example failed

## Implementation Steps

### 1. Create Example Validation Script

Create a script or justfile recipe that:
1. Runs the template generator to ensure `.gleam` files are generated
2. Builds each example project
3. Reports success/failure for each

### 2. Update Justfile

Add new recipes to `justfile`:

```just
# Validate all examples build successfully
check-examples:
    @echo "Validating examples..."
    @just run  # Generate .gleam files from .lustre
    @for dir in examples/*/; do \
        echo "Building $dir..."; \
        (cd "$dir" && gleam deps download && gleam build) || exit 1; \
    done
    @echo "All examples build successfully!"

# Run all checks including examples
check: format-check lint test check-examples
    @echo "All checks passed!"

# CI pipeline with examples
ci: check
    @echo "CI pipeline complete!"
```

### 3. Alternative: Gleam Script Approach

If shell scripting in justfile is problematic, create a dedicated validation module:

```gleam
// scripts/validate_examples.gleam

import gleam/io
import gleam/list
import gleam/result
import simplifile

pub fn main() {
  let examples = [
    "examples/01_simple",
    "examples/02_attributes",
    "examples/03_events",
    "examples/04_control_flow",
    "examples/05_shoelace",
    "examples/06_material_web",
    "examples/07_tailwind",
    "examples/08_complete",
  ]

  let results = list.map(examples, validate_example)

  case list.all(results, fn(r) { result.is_ok(r) }) {
    True -> {
      io.println("All examples validated successfully!")
      Ok(Nil)
    }
    False -> {
      io.println("Some examples failed validation!")
      Error(Nil)
    }
  }
}

fn validate_example(path: String) -> Result(Nil, String) {
  // Check directory exists
  case simplifile.is_directory(path) {
    True -> {
      io.println("Validating: " <> path)
      // Would need shellout for gleam build
      Ok(Nil)
    }
    False -> {
      io.println("Missing: " <> path)
      Error("Missing example: " <> path)
    }
  }
}
```

### 4. Update PLAN.md Task Table

Add task 009 to the epic's task breakdown table.

### 5. GitHub Actions Integration

If using GitHub Actions, ensure the workflow calls `just ci`:

```yaml
# .github/workflows/ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: "26"
          gleam-version: "1.0"
      - run: just ci
```

## Justfile Changes

Update existing `check` recipe:

```just
# Before (current)
check: format-check lint test

# After (with examples)
check: format-check lint test check-examples
```

Update or add CI recipe:

```just
# Full CI pipeline
ci: check
    @echo "CI complete - all checks passed"
```

## Expected Output

When running `just check`:

```
Formatting check... OK
Linting... OK
Running tests... OK
Validating examples...
Building examples/01_simple... OK
Building examples/02_attributes... OK
Building examples/03_events... OK
Building examples/04_control_flow... OK
Building examples/05_shoelace... OK
Building examples/06_material_web... OK
Building examples/07_tailwind... OK
Building examples/08_complete... OK
All examples build successfully!
All checks passed!
```

When an example fails:

```
Building examples/03_events... FAILED
error: Compilation failed in examples/03_events
  → src/components/counter.gleam:15: Unknown variable `on_increment`
Example validation failed!
```

## Verification Checklist

- [ ] `just check-examples` runs independently
- [ ] `just check` includes example validation
- [ ] `just ci` includes example validation
- [ ] All 8 examples pass validation
- [ ] Failure in one example fails the whole check
- [ ] Error messages clearly identify failing example
- [ ] Works in CI environment (GitHub Actions)

## Files to Modify

- `justfile` - Add `check-examples` recipe, update `check` recipe
- `.claude/plan/learning_examples/PLAN.md` - Add task 009 to table
- `.claude/plan/learning_examples/tasks/README.md` - Add task 009 status

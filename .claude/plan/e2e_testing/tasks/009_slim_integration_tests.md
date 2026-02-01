# Task 009: Slim Integration Tests

## Description

Refactor the integration tests (`test/integration/pipeline_test.gleam`) to remove redundant string-pattern verification tests. Once E2E tests prove that generated code compiles and renders correctly, many string.contains() checks become redundant.

## Dependencies

- 007_ssr_html_tests - E2E tests must exist before removing redundant integration tests

## Success Criteria

1. Integration tests focus on error handling and edge cases
2. Redundant string-pattern tests removed
3. All remaining tests pass
4. Test file is significantly smaller (~50% reduction)
5. Clear separation of concerns between integration and E2E tests

## Background

The current `integration_test.gleam` (423 lines) contains two types of tests:

### Tests to KEEP (error handling + edge cases)
- `unclosed_tag_error_test`
- `unclosed_expression_error_test`
- `unclosed_if_error_test`
- `empty_params_test`
- `multiple_roots_uses_fragment_test`
- `nested_control_flow_test`
- `self_closing_tags_test`
- `html_comments_ignored_test`
- `escaped_braces_test`
- `generated_code_has_correct_hash_test`
- `large_template_performance_test`
- `full_example_from_plan_test` (valuable as documentation)

### Tests to REMOVE (redundant with E2E)
- `basic_template_generates_test` - E2E proves it compiles
- `basic_template_imports_test` - E2E proves imports work
- `all_attributes_generate_test` - E2E proves attributes work
- `if_else_generates_test` - E2E proves control flow works
- `each_loop_generates_test` - E2E proves loops work
- `case_match_generates_test` - E2E proves case works
- `user_imports_included_test` - E2E proves imports included
- `event_handler_variations_test` - E2E proves events work

## Implementation Steps

### 1. Verify E2E Tests Cover Removed Tests

Before removing any test, verify E2E tests cover the same scenarios:

| Integration Test | E2E Coverage |
|-----------------|--------------|
| `basic_template_generates_test` | `build_test` + `ssr_test` basic |
| `all_attributes_generate_test` | `build_test` + `ssr_test` attributes |
| `if_else_generates_test` | `ssr_test` control flow |
| `each_loop_generates_test` | `ssr_test` control flow |
| `case_match_generates_test` | `ssr_test` control flow |
| `event_handler_variations_test` | `build_test` events |

### 2. Create Backup

```bash
cp test/integration/pipeline_test.gleam test/integration/pipeline_test.gleam.backup
```

### 3. Remove Redundant Tests

Delete the following test functions:
- `basic_template_generates_test`
- `basic_template_imports_test`
- `all_attributes_generate_test`
- `if_else_generates_test`
- `each_loop_generates_test`
- `case_match_generates_test`
- `user_imports_included_test`
- `event_handler_variations_test`

### 4. Reorganize Remaining Tests

Group remaining tests by category:

```gleam
//// Integration tests for error handling and edge cases.
//// Full pipeline verification (compile + render) is done by E2E tests.

// === Error Handling Tests ===

pub fn unclosed_tag_error_test() { ... }
pub fn unclosed_expression_error_test() { ... }
pub fn unclosed_if_error_test() { ... }

// === Edge Case Tests ===

pub fn empty_params_test() { ... }
pub fn multiple_roots_uses_fragment_test() { ... }
pub fn nested_control_flow_test() { ... }
pub fn self_closing_tags_test() { ... }
pub fn html_comments_ignored_test() { ... }
pub fn escaped_braces_test() { ... }

// === Cache Integration Tests ===

pub fn generated_code_has_correct_hash_test() { ... }

// === Performance Tests ===

pub fn large_template_performance_test() { ... }

// === Documentation Tests ===

pub fn full_example_from_plan_test() { ... }
```

### 5. Update Module Documentation

Update the module doc comment:

```gleam
//// Integration tests for the template generation pipeline.
////
//// These tests focus on:
//// - Error handling for malformed templates
//// - Edge cases (empty params, fragments, comments, etc.)
//// - Cache hash verification
//// - Performance with large templates
////
//// Full compilation and rendering verification is handled by E2E tests
//// in test/e2e/. Those tests prove generated code actually works;
//// these tests verify the pipeline handles edge cases correctly.
```

### 6. Remove Unused Imports

After removing tests, clean up imports that are no longer needed.

### 7. Verify All Tests Pass

```bash
just integration
just check
```

## Test Cases

### Test 1: Remaining Tests Pass

```bash
just integration
# All remaining tests should pass
```

### Test 2: E2E Tests Cover Removed Scenarios

```bash
just e2e
# E2E tests should cover what was removed
```

### Test 3: Full Check Passes

```bash
just check
# All tests pass together
```

## Verification Checklist

- [ ] All implementation steps completed
- [ ] Verified E2E tests cover removed integration tests
- [ ] Remaining integration tests pass
- [ ] E2E tests pass
- [ ] `just check` passes
- [ ] File size reduced (~50%)
- [ ] Clear separation between integration and E2E test purposes
- [ ] Module documentation updated

## Notes

- Keep `full_example_from_plan_test` as it serves as living documentation
- The `large_template_performance_test` stays because E2E tests might be too slow for performance testing
- Error handling tests cannot be replaced by E2E tests (E2E only tests success cases)
- If uncertain whether to remove a test, keep it
- Consider renaming file from `pipeline_test.gleam` to `edge_cases_test.gleam` if desired

## Files to Modify

- `test/integration/pipeline_test.gleam` - Remove redundant tests, reorganize remaining

## Metrics

Before: ~423 lines, ~20 test functions
After: ~200 lines, ~12 test functions (estimate)

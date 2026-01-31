# Task 012: Scanner - Orphan Cleanup

## Description
Implement the orphan cleanup functionality that removes generated `.gleam` files whose source `.lustre` files no longer exist.

## Dependencies
- Task 003: Scanner Module
- Task 004: Cache Module

## Success Criteria
1. Generated files without source are detected as orphans
2. Only files with `@generated` marker are considered for cleanup
3. Hand-written `.gleam` files are never deleted
4. Cleanup reports removed files
5. Cleanup returns count of removed files
6. Works correctly with nested directories

## Implementation Steps

### 1. Update scanner.gleam with cleanup function
```gleam
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn cleanup_orphans(root: String) -> Int {
  let removed = find_generated_files(root)
  |> list.filter_map(fn(gleam_path) {
    case simplifile.read(gleam_path) {
      Ok(content) -> {
        case is_generated(content) {
          True -> {
            let lustre_path = to_source_path(gleam_path)
            case simplifile.is_file(lustre_path) {
              Ok(True) -> Error(Nil)  // Source exists, keep it
              _ -> {
                // Source doesn't exist, this is an orphan
                case simplifile.delete(gleam_path) {
                  Ok(_) -> {
                    io.println("✗ Removed orphan: " <> gleam_path)
                    Ok(gleam_path)
                  }
                  Error(_) -> {
                    io.println("✗ Failed to remove: " <> gleam_path)
                    Error(Nil)
                  }
                }
              }
            }
          }
          False -> Error(Nil)  // Not generated, leave alone
        }
      }
      Error(_) -> Error(Nil)  // Can't read, skip
    }
  })

  list.length(removed)
}

fn is_generated(content: String) -> Bool {
  string.starts_with(content, "// @generated from ")
}
```

### 2. Add dry-run option (optional enhancement)
```gleam
pub fn find_orphans(root: String) -> List(String) {
  find_generated_files(root)
  |> list.filter(fn(gleam_path) {
    case simplifile.read(gleam_path) {
      Ok(content) -> {
        case is_generated(content) {
          True -> {
            let lustre_path = to_source_path(gleam_path)
            case simplifile.is_file(lustre_path) {
              Ok(True) -> False  // Source exists
              _ -> True  // Orphan
            }
          }
          False -> False  // Not generated
        }
      }
      Error(_) -> False
    }
  })
}
```

## Test Cases

### Test File: `test/orphan_cleanup_test.gleam`

```gleam
import gleeunit/should
import lustre_template_gen/scanner
import lustre_template_gen/cache
import simplifile
import gleam/list
import gleam/string

fn setup_test_dir(base: String) {
  let _ = simplifile.create_directory_all(base <> "/src/components")
}

fn cleanup_test_dir(base: String) {
  let _ = simplifile.delete(base)
  Nil
}

fn create_generated_file(path: String, source_name: String) {
  let content = "// @generated from " <> source_name <> "
// @hash abc123
// DO NOT EDIT

import lustre/element.{type Element}

pub fn render() -> Element(msg) {
  element.none()
}
"
  let _ = simplifile.write(path, content)
}

fn create_handwritten_file(path: String) {
  let content = "// This is a hand-written file

pub fn main() {
  io.println(\"Hello\")
}
"
  let _ = simplifile.write(path, content)
}

pub fn cleanup_removes_orphan_test() {
  let test_dir = ".test/orphan_test_1"
  setup_test_dir(test_dir)

  // Create a generated file WITHOUT a source
  create_generated_file(test_dir <> "/src/orphan.gleam", "orphan.lustre")

  // Verify file exists
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/orphan.gleam")

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should have removed 1 file
  should.equal(removed, 1)

  // File should no longer exist
  let assert Ok(False) = simplifile.is_file(test_dir <> "/src/orphan.gleam")

  cleanup_test_dir(test_dir)
}

pub fn cleanup_keeps_file_with_source_test() {
  let test_dir = ".test/orphan_test_2"
  setup_test_dir(test_dir)

  // Create source file
  let _ = simplifile.write(test_dir <> "/src/component.lustre", "<div></div>")

  // Create generated file WITH a source
  create_generated_file(test_dir <> "/src/component.gleam", "component.lustre")

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should not have removed anything
  should.equal(removed, 0)

  // File should still exist
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/component.gleam")

  cleanup_test_dir(test_dir)
}

pub fn cleanup_keeps_handwritten_files_test() {
  let test_dir = ".test/orphan_test_3"
  setup_test_dir(test_dir)

  // Create a hand-written file (no source needed, should never be deleted)
  create_handwritten_file(test_dir <> "/src/utils.gleam")

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should not have removed anything
  should.equal(removed, 0)

  // File should still exist
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/utils.gleam")

  cleanup_test_dir(test_dir)
}

pub fn cleanup_nested_directories_test() {
  let test_dir = ".test/orphan_test_4"
  setup_test_dir(test_dir)

  // Create orphan in nested directory
  create_generated_file(
    test_dir <> "/src/components/nested/orphan.gleam",
    "orphan.lustre",
  )
  let _ = simplifile.create_directory_all(test_dir <> "/src/components/nested")
  let _ = simplifile.write(
    test_dir <> "/src/components/nested/orphan.gleam",
    "// @generated from orphan.lustre\n// @hash abc\n\npub fn render() {}\n",
  )

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should have removed the orphan
  should.equal(removed, 1)

  cleanup_test_dir(test_dir)
}

pub fn cleanup_multiple_orphans_test() {
  let test_dir = ".test/orphan_test_5"
  setup_test_dir(test_dir)

  // Create multiple orphans
  create_generated_file(test_dir <> "/src/orphan1.gleam", "orphan1.lustre")
  create_generated_file(test_dir <> "/src/orphan2.gleam", "orphan2.lustre")
  create_generated_file(test_dir <> "/src/components/orphan3.gleam", "orphan3.lustre")

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should have removed all 3
  should.equal(removed, 3)

  cleanup_test_dir(test_dir)
}

pub fn cleanup_mixed_files_test() {
  let test_dir = ".test/orphan_test_6"
  setup_test_dir(test_dir)

  // Create source with generated output (should keep)
  let _ = simplifile.write(test_dir <> "/src/valid.lustre", "<div></div>")
  create_generated_file(test_dir <> "/src/valid.gleam", "valid.lustre")

  // Create orphan (should remove)
  create_generated_file(test_dir <> "/src/orphan.gleam", "orphan.lustre")

  // Create hand-written file (should keep)
  create_handwritten_file(test_dir <> "/src/utils.gleam")

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Should have removed only the orphan
  should.equal(removed, 1)

  // Verify file states
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/valid.gleam")
  let assert Ok(False) = simplifile.is_file(test_dir <> "/src/orphan.gleam")
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/utils.gleam")

  cleanup_test_dir(test_dir)
}

pub fn cleanup_empty_directory_test() {
  let test_dir = ".test/orphan_test_7"
  setup_test_dir(test_dir)

  // Run cleanup on empty directory
  let removed = scanner.cleanup_orphans(test_dir)

  // Should return 0
  should.equal(removed, 0)

  cleanup_test_dir(test_dir)
}

pub fn find_orphans_test() {
  let test_dir = ".test/orphan_test_8"
  setup_test_dir(test_dir)

  // Create orphan
  create_generated_file(test_dir <> "/src/orphan.gleam", "orphan.lustre")

  // Create valid pair
  let _ = simplifile.write(test_dir <> "/src/valid.lustre", "<div></div>")
  create_generated_file(test_dir <> "/src/valid.gleam", "valid.lustre")

  // Find orphans (without deleting)
  let orphans = scanner.find_orphans(test_dir)

  // Should find 1 orphan
  should.equal(list.length(orphans), 1)
  should.be_true(list.any(orphans, fn(p) { string.contains(p, "orphan.gleam") }))

  // Files should still exist
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/orphan.gleam")

  cleanup_test_dir(test_dir)
}

pub fn is_generated_detection_test() {
  // Test the is_generated function indirectly through cleanup behavior

  let test_dir = ".test/orphan_test_9"
  setup_test_dir(test_dir)

  // File starting with @generated marker
  let _ = simplifile.write(
    test_dir <> "/src/gen1.gleam",
    "// @generated from test.lustre\n\npub fn render() {}\n",
  )

  // File with @generated but not at start
  let _ = simplifile.write(
    test_dir <> "/src/gen2.gleam",
    "// Some comment\n// @generated from test.lustre\n\npub fn render() {}\n",
  )

  // Run cleanup
  let removed = scanner.cleanup_orphans(test_dir)

  // Only gen1 should be removed (marker at start)
  should.equal(removed, 1)

  // gen2 should still exist (marker not at start, so not detected as generated)
  let assert Ok(True) = simplifile.is_file(test_dir <> "/src/gen2.gleam")

  cleanup_test_dir(test_dir)
}
```

## Verification Checklist
- [ ] `gleam build` succeeds
- [ ] `gleam test` passes all orphan cleanup tests
- [ ] Only files with `@generated` marker are deleted
- [ ] Files with existing sources are kept
- [ ] Hand-written files are never touched
- [ ] Nested directories are handled
- [ ] Count of removed files is accurate
- [ ] `gleam run -m lustre_template_gen -- clean` works

## Notes
- The `@generated` marker MUST be at the start of the file
- This is a safety feature to prevent accidental deletion
- Consider adding a `--dry-run` flag to preview what would be deleted
- The cleanup runs automatically after generation in the main CLI

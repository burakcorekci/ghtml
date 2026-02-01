# Task 003: Scanner Module

## Description
Implement the file discovery functionality in `scanner.gleam`. This module finds all `.lustre` files in a directory tree and converts paths to their output equivalents.

## Dependencies
- Task 001: Project Setup

## Success Criteria
1. `find_lustre_files/1` recursively finds all `.lustre` files
2. Ignored directories are skipped (`build`, `.git`, `node_modules`, `_build`, `.plan`)
3. `to_output_path/1` correctly converts `.lustre` to `.gleam`
4. `find_generated_files/1` finds all `.gleam` files
5. All functions work with nested directory structures
6. Tests pass for various directory configurations

## Implementation Steps

### 1. Define ignored directories constant
```gleam
const ignored_dirs = ["build", ".git", "node_modules", "_build", ".plan"]
```

### 2. Implement find_lustre_files
```gleam
import gleam/list
import gleam/string
import simplifile

pub fn find_lustre_files(root: String) -> List(String) {
  find_recursive(root, [], ".lustre")
}

fn find_recursive(
  dir: String,
  acc: List(String),
  extension: String,
) -> List(String) {
  case simplifile.read_directory(dir) {
    Ok(entries) -> {
      list.fold(entries, acc, fn(acc, entry) {
        case list.contains(ignored_dirs, entry) {
          True -> acc
          False -> {
            let path = dir <> "/" <> entry
            case simplifile.is_directory(path) {
              Ok(True) -> find_recursive(path, acc, extension)
              _ ->
                case string.ends_with(entry, extension) {
                  True -> [path, ..acc]
                  False -> acc
                }
            }
          }
        }
      })
    }
    Error(_) -> acc
  }
}
```

### 3. Implement to_output_path
```gleam
pub fn to_output_path(lustre_path: String) -> String {
  string.replace(lustre_path, ".lustre", ".gleam")
}
```

### 4. Implement to_source_path (reverse of to_output_path)
```gleam
pub fn to_source_path(gleam_path: String) -> String {
  string.replace(gleam_path, ".gleam", ".lustre")
}
```

### 5. Implement find_generated_files
```gleam
pub fn find_generated_files(root: String) -> List(String) {
  find_recursive(root, [], ".gleam")
}
```

## Test Cases

### Test File: `test/scanner_test.gleam`

```gleam
import gleeunit/should
import lustre_template_gen/scanner
import simplifile
import gleam/list
import gleam/string

// Helper to create test directory structure
fn setup_test_dir(base: String) {
  let _ = simplifile.create_directory_all(base <> "/src/components")
  let _ = simplifile.create_directory_all(base <> "/src/pages")
  let _ = simplifile.create_directory_all(base <> "/build")
  let _ = simplifile.create_directory_all(base <> "/.git")
  let _ = simplifile.create_directory_all(base <> "/node_modules/pkg")

  // Create .lustre files
  let _ = simplifile.write(base <> "/src/app.lustre", "")
  let _ = simplifile.write(base <> "/src/components/button.lustre", "")
  let _ = simplifile.write(base <> "/src/components/card.lustre", "")
  let _ = simplifile.write(base <> "/src/pages/home.lustre", "")

  // Create files in ignored directories (should not be found)
  let _ = simplifile.write(base <> "/build/cached.lustre", "")
  let _ = simplifile.write(base <> "/.git/hooks.lustre", "")
  let _ = simplifile.write(base <> "/node_modules/pkg/template.lustre", "")

  // Create .gleam files
  let _ = simplifile.write(base <> "/src/main.gleam", "")
  let _ = simplifile.write(base <> "/src/components/button.gleam", "")
}

fn cleanup_test_dir(base: String) {
  let _ = simplifile.delete(base)
  Nil
}

pub fn find_lustre_files_test() {
  let test_dir = ".test/scanner_test_1"
  setup_test_dir(test_dir)

  let files = scanner.find_lustre_files(test_dir)

  // Should find exactly 4 .lustre files
  should.equal(list.length(files), 4)

  // Should contain expected files
  should.be_true(list.any(files, fn(f) { string.contains(f, "app.lustre") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "button.lustre") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "card.lustre") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "home.lustre") }))

  // Should NOT contain ignored directory files
  should.be_false(list.any(files, fn(f) { string.contains(f, "build/") }))
  should.be_false(list.any(files, fn(f) { string.contains(f, ".git/") }))
  should.be_false(list.any(files, fn(f) { string.contains(f, "node_modules/") }))

  cleanup_test_dir(test_dir)
}

pub fn find_lustre_files_empty_dir_test() {
  let test_dir = ".test/scanner_test_2"
  let _ = simplifile.create_directory_all(test_dir)

  let files = scanner.find_lustre_files(test_dir)
  should.equal(files, [])

  cleanup_test_dir(test_dir)
}

pub fn find_lustre_files_nonexistent_dir_test() {
  let files = scanner.find_lustre_files(".test/nonexistent_dir_xyz")
  should.equal(files, [])
}

pub fn to_output_path_test() {
  should.equal(
    scanner.to_output_path("src/app.lustre"),
    "src/app.gleam",
  )
  should.equal(
    scanner.to_output_path("src/components/button.lustre"),
    "src/components/button.gleam",
  )
  should.equal(
    scanner.to_output_path("./test.lustre"),
    "./test.gleam",
  )
}

pub fn to_source_path_test() {
  should.equal(
    scanner.to_source_path("src/app.gleam"),
    "src/app.lustre",
  )
  should.equal(
    scanner.to_source_path("src/components/button.gleam"),
    "src/components/button.lustre",
  )
}

pub fn find_generated_files_test() {
  let test_dir = ".test/scanner_test_3"
  setup_test_dir(test_dir)

  let files = scanner.find_generated_files(test_dir)

  // Should find .gleam files
  should.be_true(list.any(files, fn(f) { string.contains(f, "main.gleam") }))
  should.be_true(list.any(files, fn(f) { string.contains(f, "button.gleam") }))

  // Should NOT find .lustre files
  should.be_false(list.any(files, fn(f) { string.contains(f, ".lustre") }))

  cleanup_test_dir(test_dir)
}

pub fn path_conversion_roundtrip_test() {
  let original = "src/components/my_component.lustre"
  let gleam_path = scanner.to_output_path(original)
  let back = scanner.to_source_path(gleam_path)
  should.equal(back, original)
}
```

## Verification Checklist
- [x] `gleam build` succeeds
- [x] `gleam test` passes all scanner tests
- [x] Files in ignored directories are not found
- [x] Nested directories are searched correctly
- [x] Empty/nonexistent directories handled gracefully
- [x] Path conversion works correctly

## Notes
- The scanner doesn't read file contents, only finds paths
- Test directories should be cleaned up after tests
- Use `.test/` prefix for test directories to keep them separate
- Consider adding the `.test` directory to `.gitignore`

# Task 001: Project Setup

## Description
Initialize the Gleam project with proper structure, dependencies, and basic scaffolding. This establishes the foundation for all subsequent development.

## Dependencies
None - this is the first task.

## Success Criteria
1. `gleam.toml` contains all required dependencies
2. Project structure matches the plan
3. `gleam build` succeeds
4. `gleam test` runs (even with no tests yet)
5. `gleam run -m lustre_template_gen` executes without error (can just print "Hello")

## Implementation Steps

### 1. Initialize gleam.toml with dependencies
```toml
name = "lustre_template_gen"
version = "0.1.0"
target = "erlang"

[dependencies]
gleam_stdlib = ">= 0.34.0 and < 2.0.0"
simplifile = ">= 2.0.0 and < 3.0.0"
argv = ">= 1.0.0 and < 2.0.0"
gleam_crypto = ">= 1.0.0 and < 2.0.0"
gleam_erlang = ">= 0.25.0 and < 1.0.0"
gleam_otp = ">= 0.10.0 and < 1.0.0"

[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
```

### 2. Create directory structure
```
src/
  lustre_template_gen.gleam
  lustre_template_gen/
    types.gleam
    scanner.gleam
    cache.gleam
    parser.gleam
    codegen.gleam
    watcher.gleam
test/
  lustre_template_gen_test.gleam
```

### 3. Create placeholder modules
Each module should have a minimal implementation that compiles:
- `types.gleam` - Empty module with a comment
- `scanner.gleam` - Empty module with a comment
- `cache.gleam` - Empty module with a comment
- `parser.gleam` - Empty module with a comment
- `codegen.gleam` - Empty module with a comment
- `watcher.gleam` - Empty module with a comment

### 4. Create main entry point
```gleam
// lustre_template_gen.gleam
import gleam/io

pub fn main() {
  io.println("lustre_template_gen v0.1.0")
}
```

## Test Cases

### Test 1: Project builds
```bash
gleam build
# Expected: Build succeeds with no errors
```

### Test 2: Tests run
```bash
gleam test
# Expected: Test suite runs (0 tests is fine)
```

### Test 3: CLI executes
```bash
gleam run -m lustre_template_gen
# Expected output: "lustre_template_gen v0.1.0"
```

### Test 4: Dependencies resolve
```bash
gleam deps download
# Expected: All dependencies download successfully
```

## Verification Checklist
- [ ] `gleam build` succeeds
- [ ] `gleam test` runs without error
- [ ] `gleam run -m lustre_template_gen` prints version
- [ ] All 6 submodules exist and compile
- [ ] Directory structure matches plan

## Notes
- Keep all modules as minimal stubs initially
- Focus on getting the build working before adding functionality
- The `.plan` directory should be in `.gitignore` or excluded from scanning later

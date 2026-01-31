# Use Test Driven Development
1. Implement tests for the change that fail
2. Implement the simplest implementation that succeed the test cases
3. Refactor code to reach the least complex state where the code is:
   * Most maintainable
   * Extendible for future changes
   * Uses the most idiomatic approaches of the language and framework
   * Identify and fix any gaps/misses/edge cases

# Test your changes
* Use `gleam build` to make sure changes are building correctly. If not fix the compiler issues.
* Use `gleam test` to make sure tests are passing.
* At the end of each task, build and run the executable and execute tests to make sure that things are working correctly. You can execute these tests in a directory `.test/[timestamp]` that should be excluded from git/indexing
* Make sure all package is formatted correctly

# Complete changes
* Commit message should mention task id/name and short/concise description, ex: `005_parser_tokenizer: implemented parser tokenizer logic`
* Commit your changes
* Push changes to remote

# Cleanup Checklist

## Tests to Remove

### Trivial Tests
- [ ] Tests that assert a getter returns the field it wraps
- [ ] Tests that assert a constructor/factory sets the fields passed to it
- [ ] Tests that assert a wrapper calls the underlying function (pure delegation)
- [ ] Tests that just re-assert what the type system already guarantees
- [ ] Tests with empty bodies or only `t.Skip()`/`pytest.skip()`

### Temporary or Broken Tests
- [ ] Tests marked `Skip`/`TODO`/`FIXME` with no plan to re-enable
- [ ] Commented-out test functions
- [ ] Tests that pass but test nothing (no assertions)
- [ ] Duplicate tests covering the exact same case

### Over-specified Tests
- [ ] Tests that assert on internal implementation details (private method calls, specific log messages)
- [ ] Tests that mock everything, testing only the mock wiring
- [ ] Snapshot tests where the snapshot is never reviewed and just auto-updated

## Tests to Restructure

### File Organization
- [ ] Test in wrong file (test for `ParseConfig` should be in `config_test.go`, not `utils_test.go`)
- [ ] Test file with tests for multiple unrelated packages/modules
- [ ] Helper functions scattered across test files instead of a shared `testutil` or `_test` helper

### Pattern Violations

#### Go
- [ ] Multiple test functions that should be a single table-driven test
- [ ] Test helpers that don't call `t.Helper()`
- [ ] Subtests without descriptive names

#### TypeScript/JavaScript
- [ ] Repeated test blocks that should use `describe.each` / `it.each`
- [ ] Tests missing `describe` grouping for related cases
- [ ] Async tests missing `await` (passes but tests nothing)

#### Python
- [ ] Tests that should use `@pytest.mark.parametrize`
- [ ] Test classes inheriting `unittest.TestCase` when plain functions suffice
- [ ] Fixtures defined in test files instead of `conftest.py` when shared

## Comments to Remove
- [ ] Commented-out code blocks
- [ ] TODOs/FIXMEs referencing resolved issues or merged PRs
- [ ] Comments that restate the code (`// increment counter` above `counter++`)
- [ ] Section dividers that add no information (`// --- helpers ---`)
- [ ] License headers on internal-only files where not required

## Dead Code
- [ ] Unreachable branches (conditions that are always true/false)
- [ ] Unused helper functions in test files
- [ ] Unused imports
- [ ] Variables assigned but never read
- [ ] Functions not called from anywhere (verify with usage search)

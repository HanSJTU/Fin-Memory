# Test-Driven Development (TDD)

## Iron Law

NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.

## RED-GREEN-REFACTOR Cycle

### RED — Write Failing Test

Write one minimal test showing what should happen:
- One behavior per test
- Clear descriptive name ("and" in name? Split it)
- Real code, not mocks (unless unavoidable)
- Name describes behavior, not implementation

### Verify RED — Watch It Fail

MANDATORY. Run the specific test:
```bash
pytest tests/test_feature.py::test_behavior -v
```
Confirm: test fails (not errors), failure message is expected.

### GREEN — Minimal Code

Write the simplest code to pass. Nothing more.
**Cheating is OK:** hardcode, copy-paste, duplicate code. Fix in REFACTOR.

### Verify GREEN — Watch It Pass

```bash
pytest tests/test_feature.py::test_behavior -v
pytest tests/ -q  # check for regressions
```

### REFACTOR — Clean Up

Remove duplication, improve names, extract helpers. Keep tests green.

### Repeat

Next failing test for next behavior. One cycle at a time.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. |
| "TDD will slow me down" | TDD is faster than debugging. |

## Red Flags — STOP and Start Over

- Code before test
- Test passes immediately on first run
- "Keep as reference" or "adapt existing code"
- "This is different because..."

## Verification Checklist

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass
- [ ] All tests pass, no regressions
- [ ] Edge cases and errors covered

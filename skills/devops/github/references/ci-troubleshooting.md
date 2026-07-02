# CI Troubleshooting Quick Reference

Common CI failure patterns and diagnosis.

## Reading CI Logs

```bash
gh run view <RUN_ID> --log-failed
```

## Common Failure Patterns

### Test Failures
- **Signatures:** `FAILED tests/test_foo.py::test_bar - AssertionError`, `ModuleNotFoundError`
- **Fix:** Update assertion, add missing dep, fix flaky test

### Lint / Formatting Failures
- **Signatures:** `E302 expected 2 blank lines`, `E501 line too long`
- **Fix:** Run `ruff check --fix .`, `black .`, `isort .`

### Type Check Failures
- **Signatures:** `error: Argument 1 has incompatible type`
- **Fix:** Fix function signature, add type cast, `# type: ignore`

### Build / Compilation Failures
- **Signatures:** `ModuleNotFoundError`, `Could not find version`
- **Fix:** Add missing dep, pin compatible version, update lockfile

### Permission / Auth Failures
- **Signatures:** `Resource not accessible by integration`, `403 Forbidden`
- **Fix:** Add `permissions:` block to workflow YAML, verify secrets

### Timeout Failures
- **Signatures:** `The operation was canceled`, `exceeded the maximum execution time`
- **Fix:** Add `timeout-minutes: 10` to step, fix perf issue

## Auto-Fix Decision Tree

```
CI Failed
├── Test failure → update test/fix logic or add dependency
├── Lint failure → run formatter
├── Type error → fix types
├── Build failure → add dep or fix version pins
├── Permission error → update workflow permissions (needs user)
└── Timeout → investigate perf (may need user input)
```

## Re-running After Fix

```bash
git add <files> && git commit -m "fix: resolve CI failure" && git push
gh pr checks --watch
```

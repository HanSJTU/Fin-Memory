# Conventional Commits Quick Reference

Format: `type(scope): description`

## Types

| Type | When to use | Example |
|------|------------|---------|
| `feat` | New feature | `feat(auth): add OAuth2 login flow` |
| `fix` | Bug fix | `fix(api): handle null response from /users` |
| `refactor` | Code restructuring, no behavior change | `refactor(db): extract query builder` |
| `docs` | Documentation only | `docs: update API examples in README` |
| `test` | Adding/updating tests | `test(auth): add token refresh tests` |
| `ci` | CI/CD configuration | `ci: add Python 3.12 to test matrix` |
| `chore` | Maintenance, deps, tooling | `chore: upgrade pytest to 8.x` |
| `perf` | Performance improvement | `perf(search): add index on users.email` |
| `style` | Formatting only | `style: run black formatter on src/` |
| `build` | Build system or external deps | `build: switch from setuptools to hatch` |

## Breaking Changes

```
feat(api)!: change auth to bearer tokens

BREAKING CHANGE: API endpoints now require Bearer token.
```

## Multi-line Body

Wrap at 72 chars. Use bullet points:

```
feat(auth): add JWT-based user authentication

- Add login/register endpoints with input validation
- Add User model with argon2 password hashing
- Add token refresh endpoint with rotation

Closes #42
```

## Linking Issues

```
Closes #42    ← closes on merge
Fixes #42     ← same effect
Refs #42      ← references without closing
```

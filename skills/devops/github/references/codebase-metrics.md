# Codebase Metrics with pygount

## Prerequisites

```bash
pip install pygount
```

## Basic Summary

```bash
pygount --format=summary \
  --folders-to-skip=".git,node_modules,venv,.venv,__pycache__,.cache,dist,build,.next,.tox,.eggs" \
  .
```

## Filter by Language

```bash
pygount --suffix=py --format=summary .
pygount --suffix=py,yaml,yml --format=summary .
```

## Output Formats

- `--format=summary` — table (Language, Files, Code, Comment, %)
- `--format=json` — JSON for programmatic use

## Interpreting Results

Column headers: Language, Files, Code, Comment, %

Pseudo-languages:
- `__empty__` — empty files
- `__binary__` — binary files
- `__generated__` — auto-generated
- `__duplicate__` — identical content
- `__unknown__` — unrecognized types

## Pitfalls

1. **Always exclude .git, node_modules, venv** — without `--folders-to-skip`, pygount may take minutes or hang
2. **Markdown shows 0 code lines** — all Markdown content is classified as comments
3. **JSON files show low code counts** — use `wc -l` for accurate JSON line counts
4. **Large monorepos** — use `--suffix` to target specific languages

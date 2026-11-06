# Authoring Hermes-Agent Skills (in-repo)

Reference for creating SKILL.md files inside the hermes-agent repo tree (for skills that ship with the package).

## Frontmatter Requirements

Source of truth: `tools/skill_manager_tool.py::_validate_frontmatter`.

```yaml
---
name: my-skill-name               # lowercase, hyphens, ≤64 chars (MAX_NAME_LENGTH)
description: Use when <trigger>. <one-line behavior>.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [short, descriptive, tags]
    related_skills: [other-skill, another-skill]
---
```

Hard requirements: starts with `---` (byte 0, no leading blank), closes with `\n---\n`, parses as YAML mapping, `name` and `description` present, `description` ≤ 1024 chars, non-empty body.

## Size Limits

- Description: ≤ 1024 chars (enforced)
- Full SKILL.md: ≤ 100,000 chars (enforced, ~36k tokens)
- Target: 8-14k chars. Past 20k, split into `references/*.md`

## Directory Placement

```
skills/<category>/<name>/SKILL.md
```

Categories: `autonomous-ai-agents`, `creative`, `data-science`, `devops`, `dogfood`, `email`, `gaming`, `github`, `leisure`, `mcp`, `media`, `mlops/*`, `note-taking`, `productivity`, `red-teaming`, `research`, `smart-home`, `social-media`, `software-development`.

## Workflow

1. Survey peers: `ls skills/<category>/`
2. Draft with `write_file` to `skills/<category>/<name>/SKILL.md`
3. Validate locally:
   ```python
   import yaml, re, pathlib
   content = pathlib.Path("skills/<category>/<name>/SKILL.md").read_text()
   assert content.startswith("---")
   m = re.search(r'\n---\s*\n', content[3:])
   fm = yaml.safe_load(content[3:m.start()+3])
   assert "name" in fm and "description" in fm
   assert len(fm["description"]) <= 1024
   assert len(content) <= 100_000
   ```
4. Git add + commit

## Editing Existing In-Repo Skills

- **Small fix**: `skill_manage(action='patch', name=..., old_string=..., new_string=...)`
- **Major rewrite**: `write_file` the whole SKILL.md
- **Adding support files**: `skill_manage(action='write_file')` or `write_file`
- **Always commit** — in-repo skills are source, not runtime state

## Common Pitfalls

1. Using `skill_manage(action='create')` for in-repo skill — creates in `~/.hermes/skills/`, not the repo tree. Use `write_file`.
2. Leading whitespace or BOM before `---` — validator checks `startswith("---")`
3. Description too generic — start with "Use when ..."
4. Duplicating a peer — extend existing skill instead
5. Current session won't see new skill — skill loader is cached at session start
6. `related_skills` in-repo vs user-local — prefer in-repo links for portability

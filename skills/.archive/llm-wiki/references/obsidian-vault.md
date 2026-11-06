# Obsidian Vault Operations

When using the wiki directory as an Obsidian vault, follow these conventions for file operations.

## Vault Path

Use `OBSIDIAN_VAULT_PATH` environment variable (set in `~/.hermes/.env`). If unset, default to `~/Documents/Obsidian Vault`. For the wiki, set both `OBSIDIAN_VAULT_PATH` and `WIKI_PATH` to the same directory.

> Always resolve the vault path to a concrete absolute path before passing it to file tools. Shell variables like `$OBSIDIAN_VAULT_PATH` are NOT expanded by file tools (`read_file`, `write_file`, `patch`, `search_files`).

## Reading Notes

Use `read_file` with the resolved absolute path to the note. Prefer file tools over `cat` because they provide line numbers and pagination.

## Listing Notes

Use `search_files` with `target="files"` and the resolved vault path:
- List all markdown notes: `pattern: "*.md"` under the vault path
- List a subfolder: search under that subfolder's absolute path
- Prefer file tools over `find` or `ls`

## Searching Notes

Use `search_files` for both filename and content searches:
- Filenames: `target="files"` with a filename pattern
- Contents: `target="content"` with content regex as `pattern`, `file_glob: "*.md"` to restrict to markdown

## Creating Notes

Use `write_file` with the resolved absolute path and full markdown content. Prefer file tools over shell heredocs or `echo` to avoid shell quoting issues.

## Appending to Notes

Preferred workflow:
1. Read the target note with `read_file`
2. Use `patch` for anchored appends (add after an existing heading, or before a known trailing block)
3. Use `write_file` when rewriting the whole note is clearer than a fragile patch

## Targeted Edits

Use `patch` for focused note changes when the current content gives you stable context. Prefer over shell text rewriting.

## Wikilinks

Obsidian links notes with `[[Note Name]]` syntax. When creating notes, always use these to link related content. llm-wiki already enforces minimum 2 outbound wikilinks per page in SCHEMA.md.

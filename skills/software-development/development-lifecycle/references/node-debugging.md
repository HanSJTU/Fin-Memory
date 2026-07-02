# Node.js Debugger (node inspect + CDP)

## Two Tools

- **`node inspect`** — built-in, zero install, CLI REPL
- **CDP via `chrome-remote-interface`** — scriptable from Node/Python

## node inspect REPL

```bash
node inspect path/to/script.js
node --inspect-brk $(which tsx) path/to/script.ts  # TypeScript
```

| Command | Action |
|---|---|
| c / cont | continue |
| n / next | step over |
| s / step | step into |
| o / out | step out |
| sb('file.js', 42) | set breakpoint |
| sb('functionName') | break on function entry |
| bt | backtrace (call stack) |
| list(5) | show 5 lines of source |
| watch('expr') | evaluate on every pause |
| repl | REPL in current scope |
| exec expr | evaluate once |

### Attach to Running Process

```bash
kill -SIGUSR1 <pid>
node inspect -p <pid>
```

### Debug Hermes TUI

```bash
hermes --tui &
TUI_PID=$(pgrep -f 'ui-tui/dist/entry' | head -1)
kill -SIGUSR1 "$TUI_PID"
curl -s http://127.0.0.1:9229/json/list | jq -r '.[0].webSocketDebuggerUrl'
node inspect ws://127.0.0.1:9229/<uuid>
```

### Debug Vitest

```bash
node --inspect-brk ./node_modules/vitest/vitest.mjs run --no-file-parallelism src/app/foo.test.tsx
```

## Pitfalls

1. `--inspect-brk` pauses on first line; `--inspect` does not
2. Default port is 9229 — pass `--inspect=0` for random port
3. Child processes need separate `--inspect`
4. `node inspect` CLI does NOT follow TypeScript sourcemaps

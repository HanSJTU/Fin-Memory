# Node.js Inspect Debugger

When `console.log` isn't enough, drive Node's built-in V8 inspector from the terminal.

## Two Tools

- **`node inspect`** — built-in, zero install, CLI REPL. Best for quick poking.
- **CDP via `chrome-remote-interface`** — scriptable from Node/Python. Best for automation.

**Prefer `node inspect` first.** It's always available.

## `node inspect` REPL Quick Reference

Launch paused on first line:
```bash
node inspect path/to/script.js
node --inspect-brk $(which tsx) path/to/script.ts  # TypeScript via tsx
```

Debug REPL commands:

| Command | Action |
|---|---|
| `c` / `cont` | continue |
| `n` / `next` | step over |
| `s` / `step` | step into |
| `o` / `out` | step out |
| `pause` | pause running code |
| `sb('file.js', 42)` | set breakpoint at file.js line 42 |
| `sb('functionName')` | break on function entry |
| `cb('file.js', 42)` | clear breakpoint |
| `breakpoints` | list all breakpoints |
| `bt` | backtrace (call stack) |
| `list(5)` | show 5 lines of source |
| `watch('expr')` | evaluate on every pause |
| `repl` | REPL in current scope (Ctrl+C to exit) |
| `exec expr` | evaluate once |
| `restart` | restart script |
| `.exit` | quit |

## Attaching to a Running Process

```bash
# Enable inspector on existing process
kill -SIGUSR1 <pid>

# Attach
node inspect -p <pid>
# or by URL
node inspect ws://127.0.0.1:9229/<uuid>
```

## Debugging Hermes ui-tui

```bash
# Launch TUI
hermes --tui &
TUI_PID=$(pgrep -f 'ui-tui/dist/entry' | head -1)

# Enable inspector
kill -SIGUSR1 "$TUI_PID"

# Find WS URL
curl -s http://127.0.0.1:9229/json/list | jq -r '.[0].webSocketDebuggerUrl'

# Attach
node inspect ws://127.0.0.1:9229/<uuid>
```

### Debugging Vitest Tests Under the Debugger
```bash
cd ui-tui
node --inspect-brk ./node_modules/vitest/vitest.mjs run --no-file-parallelism src/app/foo.test.tsx
```
Then in another terminal: `node inspect -p <pid>`, `sb('src/app/foo.tsx', 42)`, `cont`.

## Heap Snapshots & CPU Profiles (CDP)

```bash
npm i -g chrome-remote-interface
```

CPU profile for 5 seconds:
```javascript
const CDP = require('chrome-remote-interface');
(async () => {
  const client = await CDP({ port: 9229 });
  await client.Profiler.enable();
  await client.Profiler.start();
  await new Promise(r => setTimeout(r, 5000));
  const { profile } = await client.Profiler.stop();
  require('fs').writeFileSync('/tmp/cpu.cpuprofile', JSON.stringify(profile));
})();
```

## Common Pitfalls

1. **Wrong line numbers in TS source** — breakpoints hit emitted JS, not `.ts`. Either break in `dist/*.js` or use CDP with sourcemaps. `node inspect` CLI does NOT follow sourcemaps.
2. **`--inspect` vs `--inspect-brk`** — `--inspect-brk` pauses on first line so you can set breakpoints before code runs.
3. **Port collisions** — default is 9229. Pass `--inspect=0` (random port).
4. **Child processes need separate `--inspect`** — not inherited from parent.
5. **Running through agent terminal** — use `pty=true` or `background=true` + `process(submit)`.

## One-Shot Recipes

**"Why is this variable undefined at line X?"**
```bash
node --inspect-brk script.js &
node inspect -p $!
# sb('script.js', X)
# cont → repl → myVariable
```

**"What's the call path into this function?"**
```bash
# debug> sb('suspectFn')
# debug> cont
# paused → bt
```

**"This async chain hangs — where?"**
```bash
# Start with --inspect (no -brk), let it run to hang, then:
# debug> pause
# debug> bt
```

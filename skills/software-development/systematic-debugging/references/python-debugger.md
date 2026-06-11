# Python Debugger (pdb + debugpy)

Quick-reference for debugging Python code during root cause investigation.

## Three Tools, Picked by Situation

| Tool | When |
|---|---|
| **`breakpoint()` + pdb** | Local, interactive, simplest. Add `breakpoint()` in source, run normally, get REPL at that line. |
| **`python -m pdb`** | Launch script under pdb with no source edits. |
| **`debugpy`** | Remote / headless / attach to running process. Use for long-lived processes (gateways, daemons). |
| **`remote-pdb`** | Agent-friendliest remote debugger — gives you a plain `(Pdb)` prompt over TCP. Usually what you want over full DAP. |

**Start with `breakpoint()`.** It's the cheapest thing that works.

## pdb Quick Reference

Inside any `(Pdb)` prompt:

| Command | Action |
|---|---|
| `n` | next line (step over) |
| `s` | step into |
| `r` | return from current function |
| `c` | continue |
| `l` / `ll` | list source / full function |
| `w` | where (stack trace) |
| `u` / `d` | move up / down in stack |
| `a` | print args of current function |
| `p expr` / `pp expr` | print / pretty-print |
| `display expr` | auto-print on every stop |
| `b file:line` | set breakpoint |
| `b func` | break on function entry |
| `cl N` | clear breakpoint N |
| `!stmt` | execute arbitrary Python (assignments too) |
| `interact` | drop into full Python REPL (Ctrl+D to exit) |
| `q` | quit |

The `interact` command is the most powerful — import anything, inspect complex objects. Locals read-only; use `!x = 42` from `(Pdb)` to mutate.

## Common Recipes

### Recipe 1: Local breakpoint
```python
def compute(x, y):
    result = some_helper(x)
    breakpoint()           # drops into pdb here
    return result + y
```
Run normally. Remove `breakpoint()` before committing.

### Recipe 2: Launch under pdb (no source edits)
```bash
python -m pdb path/to/script.py arg1 arg2
```

### Recipe 3: Debug pytest tests
```bash
# Drop to pdb on failure
scripts/run_tests.sh tests/test_file.py::test_name --pdb -p no:xdist

# With locals in traceback (no pdb)
scripts/run_tests.sh tests/test_file.py --showlocals --tb=long
```

**IMPORTANT:** pdb does NOT work under xdist. Always use `-p no:xdist` or `-n 0`.

### Recipe 4: Post-mortem on exception
```python
import pdb, sys
try:
    run_the_thing()
except Exception:
    pdb.post_mortem(sys.exc_info()[2])
```

### Recipe 5: Remote debug with debugpy
```bash
# Launch with debugger waiting
python -m debugpy --listen 127.0.0.1:5678 --wait-for-client your_script.py
```

### Recipe 6: Agent-friendly remote-pdb
```python
# In code at the point you want to debug:
from remote_pdb import set_trace
set_trace(host="127.0.0.1", port=4444)   # blocks until connection
```

Then from agent terminal:
```bash
nc 127.0.0.1 4444
# You get a (Pdb) prompt
```

## Common Pitfalls

1. **pdb under pytest-xdist silently does nothing** — use `-p no:xdist` or `-n 0`
2. **`breakpoint()` in CI / non-TTY hangs the process** — never commit. Pre-commit grep: `rg -n 'breakpoint\(\)' --type py`
3. **`PYTHONBREAKPOINT=0`** disables all `breakpoint()` calls
4. **`debugpy.listen` without `wait_for_client()`** continues execution
5. **Attach to PID fails on hardened kernels** — `ptrace_scope=1` blocks it
6. **Threads** — pdb only debugs current thread. Use debugpy for multithreaded
7. **asyncio** — pdb works in coroutines. `await` in pdb requires Python 3.13+
8. **`scripts/run_tests.sh` strips credentials** — debug with raw `pytest` first

## One-Shot Recipes

**"Why is this dict missing a key?"**
```python
breakpoint()
# (Pdb) pp d
# (Pdb) w
```

**"This test passes in isolation but fails in the suite."**
```bash
source .venv/bin/activate
python -m pytest tests/ -x --pdb -p no:xdist
```

**"My async handler deadlocks."**
```python
from remote_pdb import set_trace
set_trace(host="127.0.0.1", port=4444)
```
Trigger it, then `nc 127.0.0.1 4444`, then `w` + `!import asyncio; asyncio.all_tasks()`

**"Post-mortem on crash in subprocess."**
```bash
PYTHONFAULTHANDLER=1 python -m pdb -c continue path/to/entrypoint.py
```

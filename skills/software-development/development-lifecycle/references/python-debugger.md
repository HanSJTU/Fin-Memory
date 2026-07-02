# Python Debugger (pdb + debugpy)

## Three Tools by Situation

| Tool | When |
|---|---|
| `breakpoint()` + pdb | Local, interactive, simplest |
| `python -m pdb` | Launch under pdb with no source edits |
| `debugpy` | Remote / headless / attach to running process |
| `remote-pdb` | Agent-friendliest — plain pdb prompt over TCP |

## pdb Quick Reference

| Command | Action |
|---|---|
| n | next line (step over) |
| s | step into |
| r | return from current function |
| c | continue |
| l / ll | list source / full function |
| w | where (stack trace) |
| u / d | move up / down in stack |
| a | print args of current function |
| p expr | print expression |
| pp expr | pretty-print |
| b file:line | set breakpoint |
| cl N | clear breakpoint N |
| interact | drop into full Python REPL |
| q | quit |

## Common Recipes

### Local breakpoint
```python
breakpoint()  # drops into pdb here
```

### Launch under pdb
```bash
python -m pdb path/to/script.py arg1 arg2
```

### Debug pytest
```bash
pytest tests/test_file.py --pdb -p no:xdist
```

### Remote debug (remote-pdb)
```python
from remote_pdb import set_trace
set_trace(host="127.0.0.1", port=4444)
# Then from terminal: nc 127.0.0.1 4444
```

## Pitfalls

1. pdb under pytest-xdist silently does nothing — use `-p no:xdist` or `-n 0`
2. `breakpoint()` in CI hangs the process — pre-commit grep: `rg -n 'breakpoint\\(\\)'`
3. `PYTHONBREAKPOINT=0` disables all breakpoint() calls
4. Threads — pdb only debugs current thread
5. asyncio — pdb works in coroutines; await in pdb requires Python 3.13+

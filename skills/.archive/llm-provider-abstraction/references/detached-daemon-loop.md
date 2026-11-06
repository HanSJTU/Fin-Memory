# Run a Fully Detached Daemon Research Loop

Run an ai-quant-lab research loop as a **fully daemonized process** — completely
detached from the Hermes background-process lifecycle, surviving terminal timeouts,
SIGTERM, and session closure.

## When to use this pattern

Use the daemon pattern instead of `terminal(background=true)` when:

- The run will exceed 5+ minutes
- You need real-time progress updates **during** the run
- Background processes keep getting killed (exit code 143 = SIGTERM, or
  `tcsetattr: Inappropriate ioctl for device`)
- You want a persistent PID you can monitor/kill independently
- The Hermes background process lifecycle expires before the research loop

## Architecture

```
run_detached.py
    │
    ├─ First fork (parent exits immediately)
    │   └─ Child calls os.setsid() → new session, no controlling terminal
    │       └─ Second fork (first child exits)
    │           └─ Grandchild redirects stdio to log file
    │               ├─ Writes PID to research_pid.txt
    │               ├─ Writes progress to research_progress.json (every iteration)
    │               └─ Runs research loop → writes final results
    │
    └─ Controller (Hermes)
        └─ Every 60s: reads research_progress.json → reports to user
```

## The daemon setup code

Place this at the beginning of your runner script, before any imports that
might fail:

```python
import os, sys, time
from pathlib import Path

PROGRESS_FILE = Path("/tmp/research_progress.json")
PID_FILE = Path("/tmp/research_pid.txt")
OUTPUT_LOG = Path("/tmp/research_output.log")

# ── Detach from parent process ────────────────────────────────────
pid = os.fork()
if pid > 0:
    PID_FILE.write_text(str(pid))
    sys.exit(0)  # parent exits → Hermes sees exit_code=0 immediately

os.setsid()      # new session, no controlling terminal
pid2 = os.fork()
if pid2 > 0:
    sys.exit(0)  # first child exits → grandchild is truly orphaned

# Grandchild: redirect stdio to log file
log_fh = open(OUTPUT_LOG, "w", buffering=1)
os.dup2(log_fh.fileno(), sys.stdout.fileno())
os.dup2(log_fh.fileno(), sys.stderr.fileno())
log_fh.close()

PID_FILE.write_text(str(os.getpid()))
```

**Important:** The parent `sys.exit(0)` means `terminal(background=true)` will
report `exit_code: 0` immediately with no further output. This is **correct
behaviour** — the grandchild continues running.

## Structured JSON progress file

Write a JSON dict to `PROGRESS_FILE` on every significant event:

```python
progress = {
    "iteration": 5,
    "status": "critic_killed",   # or "propose", "sandbox_error", "accepted", "complete"
    "detail": "[005] critic killed: ...first 80 chars...",
    "timestamp": "15:27:40",
    "elapsed_s": 93.5,
}
PROGRESS_FILE.write_text(json.dumps(progress, indent=2))
```

The Hermes controller polls this file:

```bash
cat /tmp/research_progress.json
# → {"iteration": 42, "status": "critic_killed", ...}
```

## Poll the progress during the run

From the controller session:

```python
# Every 60 seconds:
terminal("cat /tmp/research_progress.json")
```

Parse the JSON for current iteration, status, elapsed time.

## Full template: `run_detached.py`

```python
#!/usr/bin/env python3
"""Fully detached daemon runner with JSON progress reporting."""

import functools, json, os, signal, sys, time
from pathlib import Path

PROGRESS_FILE = Path("/tmp/research_progress.json")
PID_FILE = Path("/tmp/research_pid.txt")
OUTPUT_LOG = Path("/tmp/research_output.log")

# ── Helpers ───────────────────────────────────────────────────────
t0 = time.time()

def write_progress(iteration, status, detail=""):
    data = {
        "iteration": iteration,
        "status": status,
        "detail": detail[:80],
        "timestamp": time.strftime("%H:%M:%S"),
        "elapsed_s": round(time.time() - t0, 1),
    }
    if PROGRESS_FILE.exists():
        try:
            existing = json.loads(PROGRESS_FILE.read_text())
            existing.update(data)
            data = existing
        except Exception:
            pass
    PROGRESS_FILE.write_text(json.dumps(data, indent=2))

# ── 1. Load API key ──────────────────────────────────────────────
_env = Path.home() / ".hermes" / ".env"
if _env.exists():
    for _line in _env.read_text().splitlines():
        if _line.startswith("DEEPSEEK_API_KEY"):
            os.environ["LLM_API_KEY"] = _line.split("=", 1)[1]
            break

# ── 2. Force provider config ─────────────────────────────────────
os.environ["LLM_PROVIDER"] = "openai"
os.environ["LLM_BASE_URL"] = "https://api.deepseek.com"
os.environ["AI_QUANT_LAB_MODEL"] = "deepseek-chat"   # NOT reasoning
os.environ["AI_QUANT_LAB_ANNUALIZATION"] = "8760"
os.environ["AI_QUANT_LAB_COST_BPS"] = "10"
os.environ["AI_QUANT_LAB_TARGET_SURVIVORS"] = "3"
os.environ["AI_QUANT_LAB_MEMORY_DB"] = "/tmp/research_memory.db"

# ── 3. Daemonization (fork twice) ────────────────────────────────
pid = os.fork()
if pid > 0:
    PID_FILE.write_text(str(pid))
    sys.exit(0)   # → Hermes sees exit_code=0 immediately

os.setsid()
pid2 = os.fork()
if pid2 > 0:
    sys.exit(0)

log_fh = open(OUTPUT_LOG, "w", buffering=1)
os.dup2(log_fh.fileno(), sys.stdout.fileno())
os.dup2(log_fh.fileno(), sys.stderr.fileno())
log_fh.close()
PID_FILE.write_text(str(os.getpid()))
write_progress(-1, "starting", "Loading data...")

# ── 4. Imports and token tracking ────────────────────────────────
import pandas as pd
from ai_quant_lab.config import settings
from ai_quant_lab.agents.memory import ResearchMemory
from ai_quant_lab.agents.base import call_claude
from ai_quant_lab.backtest.engine import BacktestConfig
from ai_quant_lab.orchestrator.loop import LoopConfig, run_research_loop

token_log = []
original = call_claude

@functools.wraps(call_claude)
def tracked(*args, **kwargs):
    t0l = time.time()
    r = original(*args, **kwargs)
    token_log.append({
        "model": r.model,
        "input_tokens": r.usage.get("input_tokens", 0),
        "output_tokens": r.usage.get("output_tokens", 0),
        "elapsed_s": round(time.time() - t0l, 1),
    })
    return r

import ai_quant_lab.agents.base as bm
import ai_quant_lab.agents.hypothesis as hm
import ai_quant_lab.agents.critic as cm
import ai_quant_lab.agents.code as cdm
import ai_quant_lab.agents.risk as rm
for mod in [bm, hm, cm, cdm, rm]:
    mod.call_claude = tracked

# ── 5. Load data ─────────────────────────────────────────────────
price_data = pd.read_csv(
    "/home/ubuntu/projects/market_data/btc_usdt_1h_close.csv",
    index_col="date", parse_dates=True,
)["close"]

write_progress(-1, "loaded", f"{len(price_data)} bars")

loop_config = LoopConfig(
    market_description="1-hour bars on BTC/USDT spot on Binance. 24/7 market...",
    market_type="crypto",
    iterations=100,
    target_survivors=3,
    backtest_config=BacktestConfig(cost_bps=10, annualization=8760),
    annualization=8760,
)

# ── 6. Run with progress logging ─────────────────────────────────
def tracked_log(msg):
    print(msg, flush=True)
    if msg.startswith("[") and "] " in msg:
        try:
            it = int(msg[1:].split("]")[0])
            st = "critic_killed" if "critic killed" in msg else \
                 "propose" if "propose" in msg else "running"
            write_progress(it, st, msg.split("—")[-1][:80] if "—" in msg else msg)
        except (ValueError, IndexError):
            pass

write_progress(-1, "running", "Loop started")
artifacts, survivors = run_research_loop(price_data, loop_config, memory=ResearchMemory(settings.memory_db), log=tracked_log)

# ── 7. Final summary ─────────────────────────────────────────────
total_in = sum(l["input_tokens"] for l in token_log)
total_out = sum(l["output_tokens"] for l in token_log)
result = {
    "status": "complete",
    "iterations": len(artifacts),
    "accepted": sum(1 for a in artifacts if a.accepted),
    "survivors": len(survivors),
    "wall_time_s": round(time.time() - t0),
    "llm_calls": len(token_log),
    "total_tokens": total_in + total_out,
    "input_tokens": total_in,
    "output_tokens": total_out,
}
PROGRESS_FILE.write_text(json.dumps(result, indent=2))
```

## Controller-side polling recipe

### User-expectation: periodic progress updates

When the user asks you to run a long process (especially one they set up and
want to monitor), **push regular status updates to them** — don't wait for
them to ask. The user's expectation is:

> "跑一次100次循环，运行期间，每隔1分钟给我一次状态信息同步"

Pattern: poll the progress file every 40-60 seconds and summarize:

```text
📡 16:05 — 第3次同步
| 迭代 | 8 / 50 |
| 通过Critic | 3次 ✅ |
| 存活策略 | 0 |
| 预计完成 | 16:12 |
```

**Every poll should produce a visible update in chat.** If you poll silently
(internal `terminal()` calls without reporting), the user sees nothing and
will ask "为什么没有定时汇报？"

### Hermes-side polling recipe

From the Hermes session, start the daemon and poll:

```python
# 1. Start the detached daemon
terminal("rm -f /tmp/research_progress.db && .venv/bin/python -u run_detached.py")

# 2. A few seconds later, verify it's alive
terminal("cat /tmp/research_progress.json")
# → {"iteration": -1, "status": "running", ...}

# 3. Poll every ~60s
terminal("sleep 60 && cat /tmp/research_progress.json")
# → {"iteration": 35, "status": "critic_killed", ...}

# 4. Kill if needed
terminal("kill $(cat /tmp/research_pid.txt)")
```

## Pitfalls

- **Log file buffering**: Even with `buffering=1`, the log file may lag by a
  few seconds. The JSON progress file is more reliable for status checks.
- **Disk space**: Each iteration adds ~1 line to the log. 100 iterations
  = ~200 lines (~10KB). Not a concern.
- **Stale PID file**: If the grandchild dies unexpectedly, the PID file
  points to a dead process. Always check `ps` before acting on the PID:
  ```bash
  ps -p $(cat /tmp/research_pid.txt) > /dev/null 2>&1 && echo "alive" || echo "dead"
  ```
- **Two-fork rationale**: A single fork with `setsid()` can still be adopted
  by the session leader when the Hermes background process exits. The second
  fork guarantees true orphaning — the grandchild is not a session leader and
  cannot be re-acquired by a controlling terminal.
- **Don't use with `notify_on_complete=true`**: The parent exits immediately
  (exit_code=0), so the notification fires right away with no meaningful
  content. Use progress file polling instead.
- **`workdir` still works**: The daemon inherits the working directory from
  its parent. Pass `workdir=...` on the terminal() call and the fork
  chain inherits it.

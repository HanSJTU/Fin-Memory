# Run a Token-Tracked Research Loop

Track every LLM call's token consumption during an ai-quant-lab research loop
by wrapping `call_claude` with a usage counter.

## Approach

Replace `call_claude` with a tracked version that appends each call's usage to
a list, then prints a summary at the end.

## Template script (`run_tracked.py`)

```python
import functools, os, time
from pathlib import Path

# ── 1. Load API key from file (not env var — env may be stale) ──────────
_env_path = Path.home() / ".hermes" / ".env"
if _env_path.exists():
    for _line in _env_path.read_text().splitlines():
        if _line.startswith("DEEPSEEK_API_KEY"):
            os.environ["LLM_API_KEY"] = _line.split("=", 1)[1]
            break

# ── 2. Force provider config (direct assignment, NOT setdefault) ────────
os.environ["LLM_PROVIDER"] = "openai"
os.environ["LLM_BASE_URL"] = "https://api.deepseek.com"
os.environ["AI_QUANT_LAB_MODEL"] = "deepseek-chat"  # NOT reasoning models
os.environ["AI_QUANT_LAB_ANNUALIZATION"] = "8760"   # 1h bars
os.environ["AI_QUANT_LAB_COST_BPS"] = "10"          # crypto cost
os.environ["AI_QUANT_LAB_TARGET_SURVIVORS"] = "3"
os.environ["AI_QUANT_LAB_MEMORY_DB"] = "./research_memory.db"

# ── 3. Token tracking wrap ──────────────────────────────────────────────
token_log = []
from ai_quant_lab.agents.base import call_claude as original_call

def tracked_call(*args, **kwargs):
    t0 = time.time()
    resp = original_call(*args, **kwargs)
    token_log.append({
        "model": resp.model,
        "input_tokens": resp.usage.get("input_tokens", 0),
        "output_tokens": resp.usage.get("output_tokens", 0),
        "elapsed_s": round(time.time() - t0, 1),
    })
    return resp

# Patch all modules that already imported call_claude
import ai_quant_lab.agents.base as base_mod
import ai_quant_lab.agents.hypothesis as hyp_mod
import ai_quant_lab.agents.critic as crit_mod
import ai_quant_lab.agents.code as code_mod
import ai_quant_lab.agents.risk as risk_mod
for mod in [base_mod, hyp_mod, crit_mod, code_mod, risk_mod]:
    mod.call_claude = tracked_call

# ── 4. Load data and run ────────────────────────────────────────────────
import pandas as pd
from ai_quant_lab.config import settings
from ai_quant_lab.agents.memory import ResearchMemory
from ai_quant_lab.backtest.engine import BacktestConfig
from ai_quant_lab.orchestrator.loop import LoopConfig, run_research_loop

price_data = pd.read_csv(
    "/home/ubuntu/projects/market_data/btc_usdt_1h_close.csv",
    index_col="date", parse_dates=True,
)["close"]

loop_config = LoopConfig(
    market_description=(
        "1-hour bars on BTC/USDT spot on Binance. 24/7 market, "
        "highly volatile with fat tails. Intraday session patterns: "
        "Asian, European, US dynamics differ significantly."
    ),
    market_type="crypto",
    iterations=100,
    target_survivors=3,
    backtest_config=BacktestConfig(cost_bps=10, annualization=8760),
    annualization=8760,
)

with ResearchMemory(settings.memory_db) as memory:
    artifacts, survivors = run_research_loop(price_data, loop_config, memory=memory)

# ── 5. Print summary ────────────────────────────────────────────────────
total_in = sum(t["input_tokens"] for t in token_log)
total_out = sum(t["output_tokens"] for t in token_log)
print(f"Iterations: {len(artifacts)}  Accepted: {sum(a.accepted for a in artifacts)}")
print(f"Survivors:  {len(survivors)}")
print(f"LLM calls:  {len(token_log)}")
print(f"Tokens:     {total_in:,} in + {total_out:,} out = {total_in+total_out:,} total")
```

## Key env var notes

| Var | `setdefault` (wrong) | Direct assignment (right) |
|-----|---------------------|--------------------------|
| `LLM_API_KEY` | Skips if parent process already set it — silently fails | Always takes effect |
| `AI_QUANT_LAB_MODEL` | Same issue | Use `os.environ["KEY"] = val` |
| `LLM_BASE_URL` | Same issue | Use `os.environ["KEY"] = val` |

## Progress reporting during long runs

Three approaches for getting live progress from a 50-100 iteration loop:

1. **Periodic `process(action='log')`** — works only after enough output
   accumulates; `poll()` shows a limited preview.
2. **Write to a file** — redirect output to a temp file and read with
   `read_file()` while the process runs. Use `>> file` with `sync` to force
   writes. Most reliable for Hermes background processes.
3. **Batch mode** — run 10 iterations at a time, report, repeat. Most reliable
   for getting intermediate status updates.

## Running in a Hermes background process

When launching a long-running Python script via `terminal(background=true)`,
several buffering and shell pitfalls can cause silent failures.

### Pitfall 1: `source venv/bin/activate` crashes in non-TTY shells

**Never** source a virtualenv activate script in a Hermes background process.
The `activate` script calls `tcsetattr` which fails with:

```
bash: [PID: 1 (255)] tcsetattr: Inappropriate ioctl for device
```

This crashes the bash shell immediately (exit code 143 = SIGTERM), killing
your Python subprocess before it produces any output.

**Fix:** Use the full path to the venv Python interpreter directly:
```bash
# WRONG — crashes in background:
source .venv/bin/activate && python run_tracked.py

# RIGHT — survives background:
/home/ubuntu/projects/my-project/.venv/bin/python -u run_tracked.py
```

### Pitfall 2: Python stdout buffering in piped background processes

Even with `python -u`, stdout may be buffered when the output is piped
through the Hermes background capture. Output may not appear in `poll()` or
`log()` until the process exits.

**Fix — three-layer defense:**
```python
# Layer 1: -u flag (Python unbuffered)
# Layer 2: flush=True on every print
print = functools.partial(print, flush=True)
# Layer 3: write progress to a file as a fallback
with open("/tmp/progress.txt", "a") as f:
    f.write(f"[{timestamp}] {message}\n")
```

Then read the file periodically with `terminal("cat /tmp/progress.txt")`.

### Pitfall 3: `stdbuf -oL` vs `| cat`

`stdbuf -oL` sets line buffering at the C library level and can help when
`python -u` alone isn't enough. Piping through `| cat` also forces
passthrough. Use both together:
```bash
stdbuf -oL python -u run.py 2>&1 | cat
```

## Pitfalls

- **Reasoning models** (`deepseek-v4-flash`, `o1`, `o3-mini`) may return empty
  `content` because all output tokens are consumed by reasoning/thinking.
  `finish_reason: "length"` + empty string = reasoning ate the budget.
  Fix: use `deepseek-chat` (non-reasoning) or raise `max_tokens` to >=4096.
- **Prompt caching is Anthropic-only** — no cost savings on DeepSeek path.
- **`extract_first_json`** may fail if the DeepSeek response has trailing
  content after the JSON closing brace. The regex `{[\\s\\S]*}` usually works
  but nested braces can confuse it.
- **`CriticVerdict` field name**: the field is `passes` (bool), not `verdict`.
  When patching the critic agent for progress reporting, use
  `result.passes` not `result.verdict`.

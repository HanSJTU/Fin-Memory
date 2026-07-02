# Spike — Throwaway Experiments

## Core Method

```
decompose → research → build → verdict
    ↑______________________________↓
                iterate
```

## 1. Decompose

Break the idea into 2-5 independent feasibility questions. Each question = one spike.

| # | Spike | Validates (Given/When/Then) | Risk |
|---|-------|----------------------------|------|
| 001 | websocket-streaming | Given a WS connection, when LLM streams, then client receives chunks <100ms | High |

**Order by risk** — the spike most likely to kill the idea runs first.

## 2. Align (for multi-spike ideas)

Present the spike table. Ask: "Build all in this order, or adjust?"

## 3. Research (per spike)

Brief it (2-3 sentences), surface competing approaches, pick one.

## 4. Build

One directory per spike: `spikes/NNN-descriptive-name/` with `README.md` + code.

**Bias toward something the user can interact with:**
1. Runnable CLI with observable output
2. Minimal HTML page
3. Small web server with one endpoint
4. Unit test with recognizable assertions

**Depth over speed** — test edge cases, follow surprising findings.

For parallel comparison spikes (002a/002b), use `delegate_task`.

## 5. Verdict

```markdown
## Verdict: VALIDATED | PARTIAL | INVALIDATED
## What worked / What didn't / Surprises / Recommendation
```

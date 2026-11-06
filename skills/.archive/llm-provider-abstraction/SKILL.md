---
name: llm-provider-abstraction
description: >
  Add runtime provider switching to a Python codebase that's hardcoded to one
  LLM SDK. Supports Anthropic (Claude) ↔ OpenAI-compatible (DeepSeek, OpenAI,
  Groq, Together, etc.) via config-level provider selection.
---

# LLM Provider Abstraction

## When to use

Any Python project that hardcodes a single LLM SDK (e.g. `anthropic.Anthropic`)
and needs to support alternate providers at runtime without a fork.

## Architecture pattern

```
config layer (env vars)
    ↓
dispatch function (routes by provider string)
    ├── _call_anthropic()     ← Anthropic SDK
    └── _call_openai()        ← openai SDK (DeepSeek, OpenAI, etc.)
    ↓
return uniform AgentResponse (text, usage, model, stop_reason)
```

## Step-by-step

### 1. Config layer — add to `config.py` (or settings module)

```python
class Settings(BaseModel):
    # Existing fields...
    anthropic_api_key: str | None   # existing, kept for backward compat

    # New provider-agnostic fields
    llm_provider: str = Field(
        default_factory=lambda: os.environ.get("LLM_PROVIDER", "anthropic"),
    )
    llm_api_key: str | None = Field(
        default_factory=lambda: os.environ.get("LLM_API_KEY"),
    )
    llm_base_url: str | None = Field(
        default_factory=lambda: os.environ.get("LLM_BASE_URL"),
    )
```

**Key env vars for users:**
| Var | Purpose | Example |
|-----|---------|---------|
| `LLM_PROVIDER` | Provider selector | `anthropic` or `openai` |
| `LLM_API_KEY` | OpenAI-compatible key | `sk-...` (DeepSeek, OpenAI) |
| `LLM_BASE_URL` | OpenAI-compatible endpoint | `https://api.deepseek.com` |
| `ANTHROPIC_API_KEY` | Anthropic key (legacy) | `sk-ant-...` |
| `AI_QUANT_LAB_MODEL` | Model name | `deepseek-chat` or `claude-sonnet-4-6` |

### 2. Require the right key per provider

```python
def require_api_key(self) -> str:
    if self.llm_provider == "openai":
        if not self.llm_api_key:
            raise RuntimeError("LLM_API_KEY not set")
        return self.llm_api_key
    # default: anthropic
    if not self.anthropic_api_key:
        raise RuntimeError("ANTHROPIC_API_KEY not set")
    return self.anthropic_api_key
```

### 3. Dispatch function — the core

Create a single public function that all agents/callers use. Keep the existing
function name for backward compatibility (e.g. `call_claude` → internal
dispatcher).

```python
def call_llm(system, messages, *, model=None, max_tokens=2048,
             temperature=0.4, cache_system=True, max_retries=3):
    provider = settings.llm_provider.lower()
    if provider == "openai":
        return _call_openai(system, messages, model=model, ...)
    return _call_anthropic(system, messages, model=model, cache_system=cache_system, ...)
```

### 4. Anthropic backend (`_call_anthropic`)

- SDK: `anthropic.Anthropic`
- API: `client.messages.create(model=..., system=..., messages=...)`
- System prompt: passed as dedicated `system` parameter (array of blocks)
- Response: `response.content[0].text`
- Prompt caching: `cache_control: {"type": "ephemeral"}` on system block
- Usage: `response.usage.input_tokens`, `output_tokens`, `cache_read_input_tokens`

### 5. OpenAI-compatible backend (`_call_openai`)

- SDK: `openai.OpenAI`
- API: `client.chat.completions.create(model=..., messages=[...])`
- System prompt: first message with `role: "system"`
- Response: `response.choices[0].message.content`
- Prompt caching: **NOT available** — `cache_system` param is silently ignored
- Usage: `response.usage.prompt_tokens`, `completion_tokens`
- Base URL: `settings.llm_base_url` (e.g. `https://api.deepseek.com`)

## Pitfalls

### `exec()` sandbox pitfalls (latent bugs exposed by provider switch)

When a project uses `exec()` with a constrained namespace to run LLM-generated
code (common in AI research/backtesting frameworks), switching providers can
expose pre-existing sandbox bugs that never triggered with the old provider's
code style.

**Checklist for `exec()` sandbox components when switching providers:**

1. **Import whitelist validation**: If the sandbox validates imports via AST
   before `exec()`, check whether the validator examines the *full dotted path*
   or only the *top-level module name*. A common bug:

   ```python
   # BUG: only checks the top-level name
   if name.name.split(".")[0] not in _ALLOWED_IMPORTS:
       raise SandboxError(f"Disallowed import: {name.name}")
   ```

   This rejects `import ai_quant_lab.features.library` because
   `"ai_quant_lab"` is checked against the whitelist, but only the full
   dotted path `"ai_quant_lab.features.library"` is in it. The fix: add the
   top-level name to the whitelist (`"ai_quant_lab"`), or change the validator
   to check the full path.

2. **`__import__` missing from safe builtins**: If the sandbox supplies a
   restricted `__builtins__` dict to `exec()`, it MUST include `__import__`.
   Without it, every `import` statement fails at runtime even though the AST
   validation passed. Fix: add `"__import__"` to the safe builtins list. It's
   safe because the AST validation already runs before `exec()` and blocks
   disallowed imports.

3. **Namespace isolation**: The `exec()` namespace should contain pre-loaded
   references to whitelisted modules (e.g. `{"np": np, "pd": pd}`) so the
   strategy code doesn't need to import them. This reduces import friction
   and catches missing references at compile time rather than runtime.

4. **Strategy function signature**: The generated code must define a function
   with the exact signature the sandbox expects. If the CodeAgent generates
   different code shapes across providers, add a wrapper or template in the
   code-generation prompt that enforces the correct signature.

**Root cause pattern:** The old provider (Claude) generated code that never
exercised certain code paths in the validation layer. When switching to a
new provider (DeepSeek, GPT, etc.), the new code style triggers latent bugs.
This is not a regression — it's a bug that was always there, now visible.
Always run a small test batch (5-10 iterations) after a provider switch to
surface these issues before committing to a full run.

### Provider-specific prompt calibration

**Critical lesson: the same system prompt produces radically different behavior
across providers.**

When you swap from Claude to DeepSeek (or vice versa), all agent system prompts
need review — especially ones with strict instructions or hard guardrails.

Example from a real migration (Claude → DeepSeek):

| Model | Prompt instruction | Result |
|-------|-------------------|--------|
| Claude Sonnet 4 | `"when in doubt, kill"` | Kills ~70% of bad ideas, lets reasonable ones through |
| DeepSeek-chat (same prompt, temperature=0.3) | `"when in doubt, kill"` | Kills **100%** of ideas — literally executes the instruction |

DeepSeek at low temperature strictly follows literal instructions. Claude
naturally applies judgment and nuance even to hard directives. This isn't a
bug in either model — it's a **prompt calibration requirement** when switching.

**Checklist when switching providers:**

1. **Review every agent system prompt** — especially critics, validators,
   and gate-keepers with "kill", "reject", "flag" instructions. Assume the
   new model takes them more literally.
2. **Calibrate strict instructions** — replace unconditional directives
   (`"when in doubt, kill"`) with nuanced versions
   (`"when in doubt, PASS — let the backtest decide. Minor concerns are NOT
   a reason to kill. Only kill for clear, fatal flaws."`)
3. **Test with a small sample first** — run 5-10 iterations and check
   behavior before a full run. A 100% kill rate (or 100% accept rate) is
   a red flag.
4. **Check temperature** — lower temperature = more literal execution.
   The new model at the old temperature may differ significantly.
5. **Run end-to-end, not just the LLM call** — provider differences in code
   generation can expose latent bugs in downstream validation components
   (sandbox import checkers, AST validators, etc.) that never triggered
   with the old provider's output style.

   **Real example:** After switching to DeepSeek, CodeAgent generated
   `import ai_quant_lab.features.library` which triggered a sandbox
   import rejection. Investigation revealed a pre-existing sandbox bug:
   the import whitelist validator checks `import_name.split('.')[0]`
   (top-level module name), but the whitelist contained full dotted paths
   like `"ai_quant_lab.features.library"`. The validation failed because
   `"ai_quant_lab"` wasn't in the whitelist, even though the fully
   qualified module was. This bug was invisible with Claude because
   Claude's generated code never used that import path.

**Model-family adjustment heuristics:**
- **Claude** → add more guardrails and constraints to prompts (Claude is
  naturally compliant; it benefits from explicit boundary instructions)
- **DeepSeek / GPT / Mistral** → relax strict language, add nuance
  (these models execute literal instructions more aggressively)
- **Reasoning models (o-series, R1, V4-Flash)** → avoid for structured
  JSON generation; use chat/instruction-tuned variants instead

### Reasoning vs chat models (OpenAI-compatible)

Some providers expose **reasoning models** alongside chat models (e.g. DeepSeek
V4 Flash, OpenAI o-series). Reasoning models consume output tokens for internal
"thinking" before producing visible content. This causes two failure modes:

1. **Empty content with `finish_reason: length`** — if `max_tokens` is too
   small, all tokens are consumed by reasoning and `choice.message.content`
   comes back as an empty string (`""`). Fix: use a non-reasoning model like
   `deepseek-chat` instead of `deepseek-v4-flash`, or set `max_tokens` high
   enough to leave room after reasoning (≥4096).
2. **Erratic JSON output** — reasoning models may embed JSON inside
   reasoning traces or return partial JSON when thinking is interrupted.
   `extract_first_json()` may fail even though the response starts with `{`.

**Recommendation**: for structured JSON generation (hypothesis proposals,
critiques, code generation), prefer the provider's chat/instruction-tuned
model variant over its reasoning variant.

### Env var `setdefault` vs direct assignment

When configuring the provider via environment variables, `os.environ.setdefault()`
silently does nothing if the variable is already set — even to an empty string
or a stale value inherited from the parent process (e.g. the Hermes agent
itself). This is insidious because it looks correct on first read.

**Wrong** (silently skips if already present):
```python
os.environ.setdefault("LLM_API_KEY", key_from_file)  # BUG: no-op if already set
```

**Right** (force overrides any inherited value):
```python
os.environ["LLM_API_KEY"] = key_from_file  # always takes effect
```

When writing a runner script that loads credentials from a `.env` or config
file, always use direct assignment (`os.environ["KEY"] = val`) — never
`setdefault`. The parent process may have exported a placeholder value that
you need to replace.

- **Function signature clash**: Anthropic has `system` as a separate parameter;
  OpenAI puts it in the `messages` array. The adapter must handle this.
- **Prompt caching is Anthropic-only**: The OpenAI-compatible API has no
  equivalent. `cache_system` param is silently ignored on the OpenAI path.
  Document this clearly so users don't expect cost savings.
- **Anthropic-specific SDK features**: `max_tokens` is per-response, not
  per-stream. SDK version differences can break response.content iteration if
  Anthropic changes the block type model.
- **OpenAI SDK TypedDict complaints**: Pyright/Pylance may complain about
  `dict[str, str]` not matching `ChatCompletionMessageParam` — this is a
  type-checker false positive; the runtime works fine.
- **Model naming**: Model names differ across providers. Don't try to validate
  them in the adapter — pass through the configured string.
- **Provider-specific response fields**: `stop_reason` differs (Anthropic:
  `"end_turn"`, OpenAI: `"stop"`). Both are valid — just pass through the raw
  value.
- **Backward compat**: Keep the original function name (`call_claude`) as
  the public API so no imports change. Only rename internally.
- **Retry strategy**: Both providers return 5xx/429 errors. The same
  exponential backoff (`1s → 2s → 4s`, 3 attempts) works for both.

## Verification

1. Run existing tests — they should all pass without any provider config
2. With `LLM_PROVIDER=anthropic` — behaviour is identical to pre-change
3. Import and construct test: `call_llm(system="test", messages=[...])` should
   succeed without error even without an API key set (it'll fail on the
   actual call, not on import)

## Reference files

- `references/ai-quant-lab-conversion.md` — full diff and rationale for
  converting the ai-quant-lab project from Anthropic-only to multi-provider
- `references/token-tracked-loop.md` — how to run a token-tracked research
  loop with progress reporting, including env var pitfalls and reasoning
  model workarounds
- `references/detached-daemon-loop.md` — how to run a 50-100 iteration
  research loop as a fully detached daemon using `os.fork()` + `os.setsid()`
  pattern, with structured JSON progress file for real-time polling.
  Use when background processes keep getting killed by SIGTERM or
  `tcsetattr` errors, or when you need live iteration-by-iteration
  progress during long runs.

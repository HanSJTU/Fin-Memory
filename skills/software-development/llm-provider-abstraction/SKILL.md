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

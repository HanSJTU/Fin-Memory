# ai-quant-lab: Anthropic → Multi-Provider Conversion

## Context

The [ai-quant-lab](https://github.com/yourname/ai-quant-lab) project was
hardcoded to the Anthropic SDK (`anthropic.Anthropic`). We converted it to
support both Anthropic and OpenAI-compatible providers (DeepSeek, OpenAI,
etc.) at runtime via env-var configuration.

## Files changed

| File | Lines changed | Purpose |
|------|---------------|---------|
| `config.py` | +32 / -3 | Added `llm_provider`, `llm_api_key`, `llm_base_url`; updated `require_api_key()` |
| `agents/base.py` | +166 / -39 | Split `call_claude` into dispatcher + `_call_anthropic` + `_call_openai` |
| `agents/__init__.py` | +6 / -1 | Updated docstring |
| `.env.example` | +22 / -6 | Added provider config examples |

## Diff summary (key excerpts)

### config.py additions

```python
llm_provider: str = Field(
    default_factory=lambda: _read_env("LLM_PROVIDER", "anthropic"),
)
llm_api_key: str | None = Field(
    default_factory=lambda: os.environ.get("LLM_API_KEY"),
)
llm_base_url: str | None = Field(
    default_factory=lambda: os.environ.get("LLM_BASE_URL"),
)
```

### require_api_key() — provider-aware

```python
def require_api_key(self) -> str:
    if self.llm_provider == "openai":
        if not self.llm_api_key:
            raise RuntimeError("LLM_API_KEY is not set. "
                "Set LLM_API_KEY=sk-... and LLM_BASE_URL=https://api.deepseek.com "
                "to use an OpenAI-compatible provider.")
        return self.llm_api_key
    # Default: Anthropic
    if not self.anthropic_api_key:
        raise RuntimeError("ANTHROPIC_API_KEY is not set. ...")
    return self.anthropic_api_key
```

### base.py — dispatcher

The original `call_claude` function became a thin dispatcher. All existing
callers (`hypothesis.py`, `critic.py`, `code.py`, `risk.py`) import
`call_claude` — no import changes needed.

```python
def call_claude(system, messages, *, model=None, max_tokens=2048,
                temperature=0.4, cache_system=True, max_retries=3):
    provider = settings.llm_provider.lower()
    if provider == "openai":
        return _call_openai(system, messages, model=model,
            max_tokens=max_tokens, temperature=temperature,
            max_retries=max_retries)
    return _call_anthropic(system, messages, model=model,
        max_tokens=max_tokens, temperature=temperature,
        cache_system=cache_system, max_retries=max_retries)
```

### _call_openai() — the new path

```python
def _call_openai(system, messages, *, model=None, max_tokens=2048,
                 temperature=0.4, max_retries=3):
    api_key = settings.require_api_key()
    base_url = settings.llm_base_url
    client = OpenAI(api_key=api_key, base_url=base_url)
    use_model = model or settings.model

    api_messages = [{"role": "system", "content": system}]
    api_messages.extend({"role": m.role, "content": m.content} for m in messages)

    # retry loop with exponential backoff (1s → 2s → 4s, 3 attempts)
    response = client.chat.completions.create(
        model=use_model, max_tokens=max_tokens,
        temperature=temperature, messages=api_messages,
    )
    text = response.choices[0].message.content or ""
    usage = {"input_tokens": response.usage.prompt_tokens,
             "output_tokens": response.usage.completion_tokens,
             "cache_read_tokens": 0, "cache_creation_tokens": 0}
    return AgentResponse(text=text, usage=usage,
                         model=response.model,
                         stop_reason=response.choices[0].finish_reason)
```

## Key differences handled

| Aspect | Anthropic | OpenAI-compatible |
|--------|-----------|-------------------|
| System prompt | `system` param (array of blocks) | First message with `role: "system"` |
| Messages API | `client.messages.create()` | `client.chat.completions.create()` |
| Response text | `response.content[0].text` | `response.choices[0].message.content` |
| Usage tokens | `input_tokens` / `output_tokens` | `prompt_tokens` / `completion_tokens` |
| Prompt caching | `cache_control: ephemeral` | Not available (ignored) |
| Model field | `response.model` | `response.model` (same shape) |

## Branch

Changes are on the `feat/llm-provider` branch.

## Tests

All 111 tests pass unchanged. The tests don't call the LLM directly — they
test the backtest engine, validation, features, and sandbox — so no test
changes were needed.

## Usage

```bash
# DeepSeek mode
export LLM_PROVIDER=openai
export LLM_API_KEY=sk-...
export LLM_BASE_URL=https://api.deepseek.com
export AI_QUANT_LAB_MODEL=deepseek-chat
python -m ai_quant_lab.run --csv btc_data.csv --market-type crypto

# Claude mode (unchanged)
export LLM_PROVIDER=anthropic
export ANTHROPIC_API_KEY=sk-ant-...
export AI_QUANT_LAB_MODEL=claude-sonnet-4-6
python -m ai_quant_lab.run --csv btc_data.csv --market-type crypto
```

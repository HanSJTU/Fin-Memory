# Debugging Hermes TUI Slash Commands

Debugging guide for slash commands spanning the Python backend, tui_gateway JSON-RPC bridge, and Ink/TypeScript frontend.

## Architecture Overview

```
Python backend (hermes_cli/commands.py)     <- canonical COMMAND_REGISTRY
       │
       ▼
TUI gateway (tui_gateway/server.py)         <- slash.exec / command.dispatch
       │
       ▼
TUI frontend (ui-tui/src/app/slash/)        <- local handlers + fallthrough
```

## Investigation Steps

1. **Check if the command exists in the TUI frontend:**
   ```bash
   search_files --pattern "/commandname" --file_glob "*.ts" --path ui-tui/
   ```

2. **Check if the command exists in the Python backend:**
   ```bash
   search_files --pattern "commandname" --path hermes_cli/commands.py --context 3
   ```

3. **Check gateway implementation:**
   ```bash
   search_files --pattern "complete.slash|slash.exec" --path tui_gateway/
   ```

## Fix: Missing Command Autocomplete

Add a `CommandDef` entry to `COMMAND_REGISTRY` in `hermes_cli/commands.py`:
```python
CommandDef("commandname", "Description", "Session",
    cli_only=True, aliases=("alias",),
    args_hint="[arg1|arg2]", subcommands=("arg1", "arg2")),
```

Add handler in `cli.py::process_command()`:
```python
elif canonical == "commandname":
    self._handle_commandname(cmd_original)
```

For gateway-available commands, add handler in `gateway/run.py`.

## Common Issues

- **Command shows in TUI but not autocomplete** → missing from COMMAND_REGISTRY
- **Command shows in autocomplete but doesn't work** → missing handler in tui_gateway or frontend
- **Command differs between CLI and TUI** → different implementations in each layer
- **Command persists config but doesn't apply live** → must also patch nanostore state (e.g. `patchUiState(...)`)
- **Gateway dispatch silently ignores** → check GATEWAY_KNOWN_COMMANDS includes canonical name

## Debugging Tactics

- **Python side hangs**: use `python-debugpy` skill, break inside `_SlashWorker.exec`
- **Ink side not reacting**: use `node-inspect-debugger` skill, break in `app.tsx` slash dispatch
- **Registry mismatch**: compare COMMAND_REGISTRY entry against TUI local command list

## Pitfalls

- Don't forget the category in CommandDef (Session, Configuration, etc.)
- `cli_only=True` commands won't work in gateway — unless `gateway_config_gate` is set
- After adding live UI state, search every consumer of the old prop/helper
- Rebuild TUI: `npm --prefix ui-tui run build` before testing

## Verification

1. Rebuild: `npm --prefix ui-tui run build`
2. Run TUI: `hermes --tui`
3. Type `/` and verify command appears in autocomplete
4. Test the command
5. If gateway-available, test from messaging platform

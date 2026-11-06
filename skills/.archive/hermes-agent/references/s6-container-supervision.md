# s6-overlay Container Supervision

Reference for modifying, debugging, or extending the s6-overlay supervision tree inside the Hermes Agent Docker image.

## Architecture

```
/init                                  ← PID 1 (s6-overlay v3.2.3.0)
├── cont-init.d                        ← oneshot setup, runs as root
│   ├── 01-hermes-setup                ← docker/stage2-hook.sh
│   │   ├── UID/GID remap
│   │   ├── chown /opt/data
│   │   ├── chown /opt/data/profiles (every boot)
│   │   ├── seed .env / config.yaml / SOUL.md
│   │   └── skills_sync.py
│   └── 02-reconcile-profiles          ← hermes_cli.container_boot
│       └── recreate /run/service/gateway-<name>/
│           → auto-start only those with prior_state == "running"
│
├── s6-rc.d (static services)
│   ├── main-hermes/run                ← exec sleep infinity (no-op slot)
│   └── dashboard/run                  ← conditional on HERMES_DASHBOARD=1
│
├── /run/service (s6-svscan watches; tmpfs)
│   ├── gateway-coder/
│   │   ├── type ("longrun")
│   │   ├── run  (exec s6-setuidgid hermes hermes -p coder gateway run)
│   │   └── down (marker — present means "registered but don't auto-start")
│   └── ...
│
└── CMD (main program) ← /opt/hermes/docker/main-wrapper.sh
```

## Key Files

| Path | Role |
|---|---|
| `Dockerfile` | s6-overlay install + cont-init.d wiring |
| `docker/stage2-hook.sh` | UID remap, chown, seed, skills sync |
| `docker/cont-init.d/02-reconcile-profiles` | Profile gateway reconciliation |
| `docker/main-wrapper.sh` | Routes user args, drops to hermes |
| `hermes_cli/service_manager.py` | S6ServiceManager: register/unregister/start/stop |
| `hermes_cli/container_boot.py` | `reconcile_profile_gateways()` |
| `hermes_cli/gateway.py::_dispatch_via_service_manager_if_s6` | Routes gateway commands to s6 |

## Quick Recipes

**Verify s6 is PID 1:**
```sh
docker exec <c> sh -c 'cat /proc/1/comm; readlink /proc/1/exe'
```

**Inspect a profile gateway service:**
```sh
docker exec <c> /command/s6-svstat /run/service/gateway-<name>
```

**Bring a service up/down:**
```sh
docker exec <c> /command/s6-svc -u /run/service/gateway-<name>  # up
docker exec <c> /command/s6-svc -d /run/service/gateway-<name>  # down
```

**Add a new static service:**
1. Create `docker/s6-rc.d/<name>/type` with `longrun\n`
2. Create `docker/s6-rc.d/<name>/run` (use `#!/command/with-contenv sh`)
3. Create `docker/s6-rc.d/<name>/dependencies.d/base`
4. Create `docker/s6-rc.d/user/contents.d/<name>`

## Common Pitfalls

- **`s6-svstat` not found via docker exec** → use absolute path `/command/s6-svstat`
- **Profile directory root-owned** → stage2-hook.sh chowns `$HERMES_HOME/profiles` on every boot
- **Service slot exists but "s6-supervise not running"** → tmpfs was wiped on restart; wait for reconciler
- **Gateway starts then immediately exits** → profile has no model/auth configured; run `hermes -p <profile> setup` first
- **Reconciler skipped a profile** → missing SOUL.md; the reconciler keys on SOUL.md presence
- **Container exits 143** → something invoked halt; let main-wrapper.sh exit normally

## Testing

```sh
docker build -t hermes-agent-harness:latest .
HERMES_TEST_IMAGE=hermes-agent-harness:latest scripts/run_tests.sh tests/docker/ -v
```

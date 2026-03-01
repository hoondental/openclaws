# openclaws

OpenClaw local management scripts (gateway/node create/start/stop) with **code/runtime split**.

## Layout
- Code/package (this repo checkout path can be anywhere)
  - `bin/` (operational scripts)
  - `systemd/` (user service templates)
  - `docs/` (command + service details)
- Runtime data (default): `${OPENCLAWS_HOME:-$HOME/openclaws}`
  - `gateways/<name>/...`
  - `nodes/<name>/...`

## Why split code and runtime?
- safer updates (replace code without touching live state)
- easier backup (runtime only)
- cleaner git repo (no working state/logs)

## Environment
- `OPENCLAWS_HOME` (optional): runtime root override
  - default: `$HOME/openclaws`

## Install (recommended)
Use `install.sh` to deploy scripts into a target install dir.

Default install dir is `/opt/openclaws`.

### Permission note (important)
If `/opt/openclaws` is not writable, **do not run `sudo ./install.sh` directly**.

Recommended flow:
```bash
sudo mkdir -p /opt/openclaws
sudo chown -R $USER:$USER /opt/openclaws
./install.sh
```

Alternative (no sudo):
```bash
./install.sh --install-dir "$HOME/openclaws"
```

```bash
./install.sh
```

Install + service templates:
```bash
./install.sh --install-service-template
```

If `openclaw` CLI is missing, installer can prompt to install it,
or you can force non-interactive install:
```bash
./install.sh --install-openclaw-if-missing
```

When openclaw is found/installed, installer also:
- appends npm global bin PATH to `~/.bashrc` if needed
- runs `source ~/.bashrc` in installer process (best effort)
- uses non-persistent npm fallback prefix (avoids breaking `nvm` via `~/.npmrc`)

If your current terminal still doesn't see `openclaw`, run:
```bash
source ~/.bashrc
```

Default OpenClaw install target version: **2026.2.26**
(you can override with `--openclaw-version`)

Install a specific OpenClaw version explicitly:
```bash
./install.sh --install-openclaw-if-missing --openclaw-version 2026.2.26
```

Install + create/start gateway/node in one shot:
```bash
./install.sh \
  --install-service-template \
  --gateway-name gw_chatgpt \
  --gateway-port 21100 \
  --node-name gw_chatgpt-1 \
  --start
```

See detailed docs:
- `docs/COMMANDS.md`
- `docs/SERVICES.md`
- `docs/TELEGRAM_SETUP.md`
- `docs/OPENAI_CODEX_SETUP.md`
- `docs/PREREQUISITES.md`

## New VM quick bootstrap (recommended)
```bash
./scripts/prereq_ubuntu.sh
./scripts/verify_env.sh
./install.sh --install-openclaw-if-missing
```

`install.sh` automatically runs environment precheck (`scripts/verify_env.sh`).
If you must bypass it (not recommended):
```bash
./install.sh --skip-env-check
```

## Create gateway
```bash
/opt/openclaws/pkg/bin/create_gateway.sh --name gw_chatgpt --ws-port 21100
```

## Create node
```bash
/opt/openclaws/pkg/bin/create_node.sh --name gw_chatgpt-1 --gateway gw_chatgpt
```

## Start/stop/status
```bash
/opt/openclaws/pkg/bin/start_gateway.sh --name gw_chatgpt
/opt/openclaws/pkg/bin/status_gateway.sh gw_chatgpt
/opt/openclaws/pkg/bin/stop_gateway.sh gw_chatgpt

/opt/openclaws/pkg/bin/start_node.sh --name gw_chatgpt-1
/opt/openclaws/pkg/bin/status_node.sh gw_chatgpt-1
/opt/openclaws/pkg/bin/stop_node.sh gw_chatgpt-1
```

## Migrate existing runtime from /opt/openclaws
If your current runtime is under `/opt/openclaws/gateways` and `/opt/openclaws/nodes`, migrate with:

```bash
/opt/openclaws/pkg/bin/migrate_runtime.sh
```

This moves runtime data to `$HOME/openclaws` and leaves symlinks at old paths for compatibility.

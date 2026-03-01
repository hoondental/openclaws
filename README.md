# openclaws-pkg

OpenClaw local management scripts (gateway/node create/start/stop) with **code/runtime split**.

## Layout
- Code/package (this repo): `/opt/openclaws/pkg`
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

## Install user services
```bash
/opt/openclaws/pkg/bin/install_systemd_user.sh
```

See detailed docs:
- `docs/COMMANDS.md`
- `docs/SERVICES.md`

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

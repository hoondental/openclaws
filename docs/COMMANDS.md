# Command Guide (`bin/*.sh`)

This document explains what each shell script does and when to use it.

## Runtime root
All scripts use runtime root:
- `OPENCLAWS_HOME` if set
- otherwise: `$HOME/openclaws`

So gateway/node working dirs are created under:
- `$OPENCLAWS_HOME/gateways/<gateway-name>`
- `$OPENCLAWS_HOME/nodes/<node-name>`

---

## Installer

### `install.sh`
Deploys this repo's operational files into a target install directory.

Default target install dir:
- `/opt/openclaws`

What it does:
1. copies `bin/` and `systemd/` into install dir
2. sets executable permission on scripts
3. patches systemd unit `ExecStart` path to the chosen install dir
4. optional: installs user service templates
5. optional: creates gateway/node and starts services

Key options:
- `--install-dir <path>` (default `/opt/openclaws`)
- `--install-service-template`
- `--install-openclaw-if-missing`
- `--openclaw-version <ver>`
- `--gateway-name <name>`
- `--gateway-port <port>`
- `--gateway-bind <mode>`
- `--gateway-model <provider/model>`
- `--node-name <name>`
- `--start`

Version pin behavior:
- if `--openclaw-version` is provided, installer uses that version
- otherwise installer reads `.openclaw-version` in repo root (if present)
- if neither is set, installer uses latest

Examples:
```bash
./install.sh
./install.sh --install-dir /opt/openclaws --install-service-template
./install.sh --install-service-template --gateway-name gw_chatgpt --gateway-port 21100 --node-name gw_chatgpt-1 --start
```

---

## Creation scripts

### `create_gateway.sh`
Creates/updates one gateway instance runtime folder and `gateway.env`.

Main actions:
- validates required args (`--name`, `--ws-port`)
- creates runtime dirs (`logs`, `run`, `config`, `state`, `.openclaw/workspace`)
- runs `openclaw setup` with isolated HOME/XDG for that instance (if no config yet)
- ensures gateway token/model/workspace in `openclaw.json`
- writes `gateway.env` (port/bind/log/config/workspace)

Example:
```bash
/opt/openclaws/pkg/bin/create_gateway.sh --name gw_chatgpt --ws-port 21100
```

### `create_node.sh`
Creates/updates one node instance linked to a gateway.

Main actions:
- reads gateway port/config path from gateway's `gateway.env`
- creates node runtime dirs (`logs`, `run`, `config`, `state`)
- creates/keeps stable `OPENCLAW_NODE_ID`
- writes `node.env` with gateway host/port/config path and node display/id

Example:
```bash
/opt/openclaws/pkg/bin/create_node.sh --name gw_chatgpt-1 --gateway gw_chatgpt
```

---

## Runner scripts (used by systemd)

### `run_gateway_instance.sh <gw_name>`
Foreground process entrypoint for one gateway instance.

Main actions:
- loads `<runtime>/gateways/<name>/gateway.env`
- reads gateway token from gateway `openclaw.json`
- exports isolated HOME/XDG/log/run env
- executes:
  `openclaw gateway run --port ... --token ... --bind ... --ws-log ... --force`

### `run_node_instance.sh <node_name>`
Foreground process entrypoint for one node instance.

Main actions:
- loads `<runtime>/nodes/<name>/node.env`
- reads gateway token from gateway config (at runtime only)
- exports isolated HOME/XDG/log/run env for node instance
- executes:
  `openclaw node run --host ... --port ... --display-name ... --node-id ...`

Options:
- `--reset-device`: removes local node state dirs before run
- `--rotate-node-id`: generates and persists a new node id

---

## Service control wrappers

### Gateway wrappers
- `start_gateway.sh --name <gw>`
- `stop_gateway.sh <gw>`
- `status_gateway.sh <gw>`
- `restart_gateway.sh <gw>`

By default these use user-systemd service:
- `openclaw-gateway@<gw>.service`

`start_gateway.sh --foreground` bypasses systemd and runs directly.

### Node wrappers
- `start_node.sh --name <node>`
- `stop_node.sh <node>`
- `status_node.sh <node>`
- `restart_node.sh <node>`

By default these use user-systemd service:
- `openclaw-node@<node>.service`

`start_node.sh --foreground` bypasses systemd and runs directly.

---

## Utility scripts

### `install_systemd_user.sh`
Installs service unit templates from `pkg/systemd` to:
- `~/.config/systemd/user`
Then reloads user daemon.

### `list.sh`
Lists runtime gateways/nodes under `OPENCLAWS_HOME`.

### `migrate_runtime.sh`
Migrates old runtime locations:
- `/opt/openclaws/gateways` -> `$OPENCLAWS_HOME/gateways`
- `/opt/openclaws/nodes` -> `$OPENCLAWS_HOME/nodes`
Creates timestamped backups and compatibility symlinks.

### `ocw-lib.sh`
Shared helper functions:
- env file loader/validation
- gateway token reader from config
- gateway config normalization helper

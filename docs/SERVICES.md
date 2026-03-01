# Services Overview

This package manages **user-level systemd services** (not system-wide root services).

## Service templates
Located in `pkg/systemd`:
- `openclaw-gateway@.service`
- `openclaw-node@.service`

After install (`install_systemd_user.sh`), they are copied to:
- `~/.config/systemd/user/`

## What each service runs

### `openclaw-gateway@<name>.service`
Executes:
```bash
/opt/openclaws/pkg/bin/run_gateway_instance.sh <name>
```
That script loads gateway env/config and starts `openclaw gateway run ...`.

### `openclaw-node@<name>.service`
Executes:
```bash
/opt/openclaws/pkg/bin/run_node_instance.sh <name>
```
That script loads node env + gateway config and starts `openclaw node run ...`.

## Lifecycle commands (user)
```bash
systemctl --user daemon-reload
systemctl --user start   openclaw-gateway@gw_chatgpt.service
systemctl --user status  openclaw-gateway@gw_chatgpt.service
systemctl --user restart openclaw-gateway@gw_chatgpt.service
systemctl --user stop    openclaw-gateway@gw_chatgpt.service

systemctl --user start   openclaw-node@gw_chatgpt-1.service
systemctl --user status  openclaw-node@gw_chatgpt-1.service
systemctl --user restart openclaw-node@gw_chatgpt-1.service
systemctl --user stop    openclaw-node@gw_chatgpt-1.service
```

## Logs
Since units use journal output:
```bash
journalctl --user -u openclaw-gateway@gw_chatgpt.service -f
journalctl --user -u openclaw-node@gw_chatgpt-1.service -f
```

Runtime folders also have `logs/` paths under `$OPENCLAWS_HOME/...`.

## Restart policy
Both units set:
- `Restart=on-failure`
- `RestartSec=2`

So process crashes should auto-restart.

# Prerequisites & Environment Checks

This project provides two helper scripts for fresh VM setup.

## 1) Install prerequisites
```bash
./scripts/prereq_ubuntu.sh
```

What it installs:
- apt packages: `git`, `curl`, `rsync`, `build-essential`, `jq`, etc.
- `nvm`
- Node.js 22 (default)

Optional node major override:
```bash
./scripts/prereq_ubuntu.sh --node 22
```

## 2) Verify environment
```bash
./scripts/verify_env.sh
```

Checks:
- required commands exist (`git`, `rsync`, `node`, `npm`)
- Node major version is >= 20
- optional: `--check-openclaw` to verify `openclaw` command

Example:
```bash
./scripts/verify_env.sh --check-openclaw
```

## 3) install.sh integration
`install.sh` now runs `scripts/verify_env.sh` automatically before install.

If you intentionally want to bypass this check:
```bash
./install.sh --skip-env-check
```

> Recommended: do not skip in production.

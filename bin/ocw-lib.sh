#!/usr/bin/env bash
set -euo pipefail

die(){ echo "ERROR: $*" >&2; exit 1; }

need_cmd(){
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

ensure_dirs(){
  local d
  for d in "$@"; do
    mkdir -p "$d"
  done
}

load_env_file(){
  local f="$1"
  [[ -s "$f" ]] || die "missing env file: $f"

  if grep -nE $'[\r]' "$f" >/dev/null 2>&1; then
    die "env file contains CRLF (^M): $f"
  fi
  if grep -nE '^\s*export\s+' "$f" >/dev/null 2>&1; then
    die "env file must not contain 'export': $f"
  fi

  set -a
  # shellcheck disable=SC1090
  source "$f"
  set +a
}

read_gateway_token(){
  local cfg="$1"
  need_cmd node
  [[ -s "$cfg" ]] || die "missing config: $cfg"

  node -e '
const fs=require("fs");
const p=process.argv[1];
const j=JSON.parse(fs.readFileSync(p,"utf8"));
process.stdout.write(j?.gateway?.auth?.token || "");
' "$cfg"
}

# openclaw.json 보정 + token 생성 + workspace 강제 + (옵션) model.primary 강제
# + (옵션) auth.profiles 껍데기 생성(provider inferred from model)
ensure_gateway_config(){
  local cfg="$1"
  local workspace="$2"
  local model_primary="${3:-}"

  need_cmd node
  [[ -s "$cfg" ]] || die "missing config: $cfg"
  [[ -n "$workspace" ]] || die "workspace path empty"

  node -e '
const fs = require("fs");
const crypto = require("crypto");

const path = process.argv[1];
const workspace = process.argv[2];
const modelPrimary = process.argv[3] || "";

let cfg = JSON.parse(fs.readFileSync(path, "utf8"));

// gateway token
cfg.gateway ??= {};
cfg.gateway.mode = cfg.gateway.mode || "local";
cfg.gateway.auth ??= {};
cfg.gateway.auth.mode = cfg.gateway.auth.mode || "token";

if (!cfg.gateway.auth.token || typeof cfg.gateway.auth.token !== "string" || cfg.gateway.auth.token.length < 10) {
  cfg.gateway.auth.token = crypto.randomBytes(24).toString("hex"); // 48 chars
}

// agents defaults
cfg.agents ??= {};
cfg.agents.defaults ??= {};
cfg.agents.defaults.workspace = workspace;

// model: 인자가 주어졌을 때만 강제
if (modelPrimary && typeof modelPrimary === "string" && modelPrimary.length > 0) {
  cfg.agents.defaults.model ??= {};
  cfg.agents.defaults.model.primary = modelPrimary;
}

cfg.agents.defaults.compaction ??= { mode: "safeguard" };

// auth.profiles "껍데기" 생성: modelPrimary가 있을 때만
// 예: openai-codex/gpt-5.3-codex -> provider = openai-codex, profile key = openai-codex:default
if (modelPrimary && typeof modelPrimary === "string" && modelPrimary.includes("/")) {
  const provider = modelPrimary.split("/")[0].trim();
  if (provider) {
    cfg.auth ??= {};
    cfg.auth.profiles ??= {};
    const profileKey = `${provider}:default`;

    // 이미 있으면 건드리지 않음 (사용자가 나중에 mode/key 등을 바꿔도 유지)
    cfg.auth.profiles[profileKey] ??= {
      provider,
      mode: "oauth"
    };
  }
}

fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + "\n", "utf8");
' "$cfg" "$workspace" "$model_primary"
}

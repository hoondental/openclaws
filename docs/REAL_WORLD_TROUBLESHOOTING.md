# Real-world Troubleshooting Notes (SSDS-mgmt)

이 문서는 실제 신규 VM에서 OpenClaw Gateway를 올리며 겪은 문제와 해결 순서를 정리한 운영 노트입니다.

## 최종 결론 (요약)

- **정석(권장) 경로가 가장 빨랐음**
  - `onboard --auth-choice openai-codex`로 해당 gateway 컨텍스트에서 OAuth 설정
- pairing 이슈처럼 보여도, 실제 원인은 다른 층(환경/PATH/Node/auth/plugin/config)인 경우가 많음

---

## 1) 설치/런타임 분리 구조

- 코드: `/opt/openclaws` (bin/systemd/docs)
- 런타임: `$HOME/openclaws` (gateways/nodes)

원칙:
- 스크립트는 일반 사용자로 실행
- 권한 부족 시 사전 `mkdir/chown`만 sudo로 1회 수행

---

## 2) 자주 발생한 문제와 원인

### A. `openclaw: command not found`
원인:
- npm 글로벌 설치 경로가 PATH에 없음
- systemd user 서비스는 interactive shell PATH와 다름

대응:
- installer에서 PATH 보강 + `~/.bashrc` 반영
- 서비스 실행 스크립트에서 `openclaw` 경로 탐색 강화
- 필요 시 `OPENCLAW_CMD`를 `gateway.env`에 명시

### B. Node 버전 충돌 (`Unexpected token '.'`, `Unexpected reserved word`)
원인:
- systemd에서 Node 12로 실행됨
- OpenClaw 2026.x는 Node 20+ 필요

대응:
- nvm Node 22 사용
- systemd override로 PATH에 nvm bin 우선 지정

### C. config invalid (`Unrecognized key: access`)
원인:
- 해당 OpenClaw 버전 스키마에 없는 키를 수동 추가

대응:
- 미지원 키 제거
- `openclaw doctor --fix` 권장 메시지 확인

### D. Telegram `/start` 후 pairing pending 없음
원인 후보:
- `/start`만으로 pairing 코드가 안 생길 수 있음
- 메시지 수신 자체/정책/토큰/업데이트 소비 상태 혼재

대응:
- `openclaw pairing list telegram` 사용 (채널 인자 포함)
- 일반 텍스트 메시지로 테스트
- webhook/getUpdates 상태 확인

### E. `No API key found for provider "openai-codex"`
원인:
- 모델 인증이 해당 gateway 컨텍스트에 없음

대응(정석):
- gateway 컨텍스트에서 `onboard --auth-choice openai-codex`
- 완료 후 gateway 재시작

---

## 3) 최종 권장 절차 (새 VM)

1. 사전 준비
```bash
./scripts/prereq_ubuntu.sh
./scripts/verify_env.sh
```

2. 설치
```bash
./install.sh --install-openclaw-if-missing
```

3. gateway/node 생성
```bash
/opt/openclaws/bin/create_gateway.sh --name gw_chatgpt --ws-port 21100
/opt/openclaws/bin/create_node.sh --name gw_chatgpt-1 --gateway gw_chatgpt
```

4. 서비스 시작
```bash
/opt/openclaws/bin/install_systemd_user.sh
/opt/openclaws/bin/start_gateway.sh --name gw_chatgpt
```

5. Codex 인증(정석)
```bash
HOME=/home/dhlee/openclaws/gateways/gw_chatgpt \
XDG_CONFIG_HOME=/home/dhlee/openclaws/gateways/gw_chatgpt/config \
XDG_STATE_HOME=/home/dhlee/openclaws/gateways/gw_chatgpt/state \
XDG_CACHE_HOME=/home/dhlee/openclaws/gateways/gw_chatgpt/state/cache \
openclaw onboard --auth-choice openai-codex
```

6. Telegram 확인
- 봇 `/start`
- 필요 시:
  - `openclaw pairing list telegram`
  - `openclaw pairing approve telegram <code>`

---

## 4) 운영 체크포인트

- `systemctl --user status openclaw-gateway@<name>.service`
- `journalctl --user -u openclaw-gateway@<name>.service -f`
- 토큰/키가 로그/채팅에 노출되면 즉시 재발급
- 설정 변경 후 반드시 restart

---

## 5) 핵심 교훈

- 문제를 pairing 레이어에서만 보지 말고, 아래 순서로 층별 확인:
  1) binary/path
  2) node runtime
  3) config schema
  4) provider auth
  5) channel updates/pairing

- 결과적으로, **정석 OAuth 온보딩이 우회보다 빠르고 안정적**이었다.

# Gateway ↔ ChatGPT Codex 연결 가이드

이 문서는 OpenClaw Gateway를 `openai-codex` 계열 모델(예: `openai-codex/gpt-5.3-codex`)과 연결하는 방법을 정리합니다.

> 핵심: ChatGPT 앱/웹에서 네가 쓰는 모델 버전(예: GPT-5.2)과, Gateway에서 지정하는 Codex 모델 버전은 **서로 독립**입니다.
> 즉, ChatGPT가 5.2여도 Gateway는 5.3-codex를 써도 되고, 반대로 맞춰도 됩니다.

---

## 1) 대상 설정 파일 위치

Gateway 인스턴스별 설정 파일:

- `$OPENCLAWS_HOME/gateways/<gateway-name>/.openclaw/openclaw.json`
- 기본값이면: `$HOME/openclaws/gateways/<gateway-name>/.openclaw/openclaw.json`

예:
`/home/dhlee/openclaws/gateways/gw_chatgpt/.openclaw/openclaw.json`

---

## 2) 최종 예제 `openclaw.json` (권장 형태)

아래는 `gateway + auth + agents.defaults.model` 구조를 한 번에 보여주는 예제입니다.

```json
{
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "<GATEWAY_TOKEN>"
    }
  },
  "auth": {
    "profiles": {
      "openai-codex:default": {
        "provider": "openai-codex",
        "mode": "oauth"
      }
    }
  },
  "agents": {
    "defaults": {
      "workspace": "/home/dhlee/openclaws/gateways/gw_chatgpt/.openclaw/workspace",
      "model": {
        "primary": "openai-codex/gpt-5.3-codex"
      },
      "compaction": {
        "mode": "safeguard"
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "<TELEGRAM_BOT_TOKEN>"
    }
  }
}
```

### 필드 설명
- `gateway.auth.token`: Gateway 접속 토큰(내부 통신용)
- `auth.profiles["openai-codex:default"]`: OpenAI Codex 인증 프로필
- `agents.defaults.model.primary`: 기본 모델 선택
- `agents.defaults.workspace`: 기본 작업 폴더
- `channels.telegram.botToken`: Telegram 봇 토큰(텔레그램 사용 시)

> `gateway.auth.token`, `botToken`은 절대 외부 공개/커밋하지 마세요.

---

## 3) 모델 버전 선택 (5.2 vs 5.3-codex)

- ChatGPT 앱/웹에서 쓰는 모델 버전과 Gateway 모델은 **강제 연동되지 않음**
- Gateway에서 원하는 모델 문자열만 정확히 지정하면 됨

예시:
- `openai-codex/gpt-5.3-codex`
- (환경에 따라) `openai-codex/gpt-5.2-codex` 같은 문자열이 존재하면 사용 가능

권장:
1. 먼저 안정적인 기본값(현재 문서 예시) 사용
2. 필요하면 테스트 VM에서 다른 모델 문자열 검증
3. 운영 반영

---

## 4) Gateway 재시작

설정 변경 후 재시작:

```bash
/opt/openclaws/bin/restart_gateway.sh <gateway-name>
```

패키지 설치 경로가 `/opt/openclaws`가 아니라면 해당 경로의 `restart_gateway.sh`를 사용하세요.

---

## 5) 동작 확인

1. Gateway 상태/로그 확인
```bash
systemctl --user status openclaw-gateway@<gateway-name>.service --no-pager -l
journalctl --user -u openclaw-gateway@<gateway-name>.service -f
```

2. 실제 메시지 전송 후 응답 모델 확인
- 응답이 정상적으로 오면 연결 성공
- 인증 이슈가 있으면 로그에 provider/auth 관련 에러가 나타남

---

## 6) 자주 발생하는 문제

### A. 인증 에러
- `auth.profiles["openai-codex:default"]` 누락/오타
- `mode` 설정 불일치

### B. 모델 문자열 오타
- `openai-codex/gpt-5.3-codex`처럼 provider/model 형식 확인

### C. 재시작 누락
- 설정 변경 후 gateway 재시작 필수

---

## 7) 권장 운영 방식

- 운영 환경은 모델 버전/설정 고정
- 변경은 테스트 VM에서 먼저 검증
- 검증 통과 후 운영에 반영

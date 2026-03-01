# Gateway ↔ ChatGPT Codex 연결 가이드

이 문서는 OpenClaw Gateway를 `openai-codex` 계열 모델(예: `openai-codex/gpt-5.3-codex`)과 연결하는 방법을 정리합니다.

---

## 1) 대상 설정 파일 위치

Gateway 인스턴스별 설정 파일:

- `$OPENCLAWS_HOME/gateways/<gateway-name>/.openclaw/openclaw.json`
- 기본값이면: `$HOME/openclaws/gateways/<gateway-name>/.openclaw/openclaw.json`

예:
`/home/dhlee/openclaws/gateways/gw_chatgpt/.openclaw/openclaw.json`

---

## 2) 모델 지정

`openclaw.json`에서 기본 모델을 지정합니다.

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai-codex/gpt-5.3-codex"
      }
    }
  }
}
```

---

## 3) 인증 프로필 지정

`auth.profiles`에 provider 프로필을 명시합니다.

```json
{
  "auth": {
    "profiles": {
      "openai-codex:default": {
        "provider": "openai-codex",
        "mode": "oauth"
      }
    }
  }
}
```

> 이미 `create_gateway.sh --model openai-codex/gpt-5.3-codex`로 생성했다면,
> 위 프로필 껍데기가 자동 생성될 수 있습니다.

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

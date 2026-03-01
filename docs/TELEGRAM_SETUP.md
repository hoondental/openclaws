# Telegram Bot Setup (Gateway 연결)

이 문서는 Telegram BotFather로 봇 토큰을 만들고, OpenClaw Gateway에 연결하는 과정을 설명합니다.

---

## 1) BotFather에서 토큰 발급

1. Telegram 앱에서 `@BotFather` 검색
2. `/newbot` 실행
3. 봇 이름(name) 입력
4. 봇 username 입력 (반드시 `bot`으로 끝나야 함, 예: `my_openclaw_bot`)
5. BotFather가 API 토큰 발급

예시 토큰 형식:
`1234567890:AA...`

> 이 토큰은 비밀번호와 동일합니다. 외부에 노출하지 마세요.

---

## 2) Gateway 설정 파일 위치 확인

Gateway 인스턴스별 config 경로는 보통:

- `$OPENCLAWS_HOME/gateways/<gateway-name>/.openclaw/openclaw.json`
- 기본값이면: `$HOME/openclaws/gateways/<gateway-name>/.openclaw/openclaw.json`

예:
`/home/dhlee/openclaws/gateways/gw_chatgpt/.openclaw/openclaw.json`

---

## 3) 토큰 넣는 위치

`openclaw.json`의 `channels.telegram` 섹션에 토큰을 넣습니다.

예시(이미 channels가 없다면 추가):

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "<BOT_TOKEN>"
    }
  }
}
```

실제 토큰으로 `<BOT_TOKEN>`을 교체하세요.

---

## 4) Gateway 재시작

설정 반영 후 gateway 재시작:

```bash
/opt/openclaws/bin/restart_gateway.sh <gateway-name>
```

(또는 패키지 설치 경로가 /opt/openclaws이면)
```bash
/opt/openclaws/bin/restart_gateway.sh gw_chatgpt
```

---

## 5) Telegram에서 봇 연결 확인

1. Telegram에서 방금 만든 봇 열기
2. `/start` 전송
3. Gateway 로그/상태에서 메시지 유입 확인

로그 확인:
```bash
journalctl --user -u openclaw-gateway@<gateway-name>.service -f
```

---

## 6) 자주 발생하는 문제

### A. 봇이 응답 없음
- 토큰 오타 확인
- gateway 재시작했는지 확인
- BotFather에서 해당 토큰이 현재 유효한지 확인

### B. 401/Unauthorized
- 토큰이 만료/재발급되어 기존 토큰이 무효화된 경우
- 새 토큰으로 `botToken` 교체 후 재시작

### C. 토큰 유출 의심
- BotFather에서 `/revoke` 또는 새 토큰 발급
- config 토큰 교체 + gateway 재시작

---

## 7) 보안 권장사항

- 토큰을 git에 커밋하지 마세요
- 공유 문서/스크린샷에 토큰이 찍히지 않게 주의
- 가능하면 별도 비밀 관리 방식(.env/secret store) 사용

---

## 빠른 체크리스트

- [ ] BotFather에서 토큰 발급
- [ ] `<gateway>/.openclaw/openclaw.json`에 `channels.telegram.botToken` 입력
- [ ] gateway 재시작
- [ ] Telegram에서 `/start` 전송
- [ ] gateway 로그에서 수신 확인

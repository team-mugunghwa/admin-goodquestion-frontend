# admin-goodquestion-frontend

굿퀘스천 관리자 콘솔. **웹 전용 Flutter 앱**입니다.

백엔드는 [admin-goodquestion-backend](https://github.com/team-mugunghwa/admin-goodquestion-backend),
사용자 서비스는 [goodquestion-frontend](https://github.com/team-mugunghwa/goodquestion-frontend) /
[goodquestion-backend](https://github.com/team-mugunghwa/goodquestion-backend)에 있습니다.

## 화면

| 메뉴 | 하는 일 |
| --- | --- |
| 대시보드 | 총 사용자, 오늘 방문자, 신규 가입, 미답변 문의, 2주 방문자 추이, 최근 관리자 활동 |
| 이야기 관리 | 이야기 / 장면 / 캐릭터 / 주제. 공개하면 사용자 앱 목록에 나갑니다 |
| 사용자 관리 | 보호자와 아이, 학습 기록, 로그인 세션 종료, 계정 정지 |
| 공지사항 관리 | 작성 / 공개 / 고정 |
| 고객센터 | 문의 확인과 답변. **답변하면 사용자에게 알림과 푸시가 나갑니다** |
| 이용안내 관리 | 도움말 문서와 노출 순서 |
| 관리자 계정 | 최고관리자 전용 |
| 감사 로그 | 관리자가 상태를 바꾼 조작 기록 |

## 시작하기

관리자 백엔드가 8081에 떠 있어야 합니다.

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=env/local.json
```

시드 관리자 계정은 `admin@goodquestion.kr` / `admin1234!` 입니다. **첫 로그인 후 바꾸세요.**

## 확인

```bash
flutter analyze && flutter test
```

## 구조

서비스 프론트엔드와 같습니다. **MVVM + 클린 아키텍처**, 상태관리는 Provider,
DI는 get_it, 라우팅은 go_router, HTTP는 Dio입니다. 자세한 내용은
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), 화면 규칙은
[docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)를 보세요.

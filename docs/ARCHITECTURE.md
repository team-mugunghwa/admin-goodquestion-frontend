# 아키텍처

**MVVM + 클린 아키텍처**, 상태관리는 **Provider**. 서비스 프론트엔드
(goodquestion-frontend)와 같은 구조입니다.

이 문서의 목적은 하나입니다: **"새 기능을 추가할 때 어떤 파일을 어디에 만드는가"**.

---

## 1. 레이어

```
presentation   View / ViewModel          화면과 상태
domain         Entity / Repository(추상)  순수 비즈니스 규칙
               / UseCase                  Flutter 를 몰라야 함
data           DataSource / RepositoryImpl  서버 통신
```

**바깥 레이어는 안쪽을 알아도 되지만, 안쪽은 바깥을 몰라야 합니다.**

- `domain` 은 `presentation` 도 `data` 도 import 하지 않습니다
- `domain` 은 `package:flutter/...`, `package:dio/...` 를 import 하지 않습니다
- `data` 가 `domain` 의 추상 Repository 를 구현하고, DI 가 둘을 연결합니다

## 2. 폴더 구조

```
lib/
+-- main.dart
+-- app.dart                    # MaterialApp.router, 전역 Provider
+-- core/
|   +-- config/                 # API 주소 등 빌드 시점 설정
|   +-- constants/app_icons.dart
|   +-- di/injector.dart        # get_it 등록 한 곳
|   +-- domain/                 # feature 두 곳 이상이 쓰는 enum
|   +-- error/                  # exceptions(data) / failure(domain)
|   +-- network/                # dio_client / page_result
|   +-- presentation/base_view_model.dart
|   +-- router/                 # 경로는 app_routes.dart 에만
|   +-- state/view_state.dart
|   +-- theme/                  # 색/간격/글자 토큰
|   +-- utils/formats.dart      # 날짜/숫자 표기
|   +-- widgets/                # 셸/표/배지/폼/대화상자
+-- features/                   # auth / dashboard / story / member / notice /
    +-- notice/                 # support / guide / audit / database
        +-- data/
        +-- domain/{entities,repositories,usecases}
        +-- presentation/{viewmodels,views,widgets}
```

### 서비스 프론트엔드와 다른 점

| 항목 | 여기 | 서비스 앱 |
| --- | --- | --- |
| DataSource 계층 | **대부분 두지 않습니다.** RepositoryImpl 안에서 Dio 를 직접 부릅니다 | 둡니다 |
| DTO 클래스 | 대부분 두지 않습니다. RepositoryImpl 의 private 함수로 변환합니다 | 둡니다 |
| Mock Repository | 없습니다 | 있습니다 |

**왜 줄였나.** 서비스 앱은 서버가 나오기 전에 화면을 먼저 만들어야 했고, 그래서
Mock Repository 를 꽂는 자리가 필요했습니다. 관리자 콘솔은 서버 API 가 먼저
나왔고, 엔드포인트당 코드가 "URL 하나 + 필드 매핑"뿐입니다. 그 위에 DataSource 와
DTO 를 얹으면 한 필드를 추가할 때 파일 넷을 열게 됩니다.

**auth 만 예외로 셋 다 둡니다.** 토큰 저장소가 있고, 재발급 흐름이 붙고,
DioClient 가 그 함수를 직접 참조합니다.

## 3. 화면 라우트

| 경로 | 화면 |
| --- | --- |
| `/login` | 로그인. 셸 바깥의 유일한 화면 |
| `/` | 대시보드 |
| `/stories`, `/stories/new`, `/stories/:storyId` | 이야기 관리 |
| `/members`, `/members/:parentId` | 사용자 관리 |
| `/notices`, `/notices/new`, `/notices/:noticeId` | 공지사항 |
| `/inquiries`, `/inquiries/:inquiryId` | 고객센터 |
| `/guides` | 이용안내 |
| `/database`, `/database/:tableName` | 데이터베이스 둘러보기. 읽기 전용 |
| `/database/diagram` | 테이블 관계도 |
| `/admins` | 관리자 계정 (최고관리자) |
| `/audit-logs` | 감사 로그 |
| `/settings` | 운영 설정. 지금은 음성 합성 엔진 전환 한 항목 |
| `/account` | 비밀번호 변경 |

**로그인 여부 판단은 `app_router.dart` 의 `redirect` 한 곳에만 둡니다.**
화면마다 검사하면 반드시 어딘가 빠뜨리고, 그 화면은 로그인 없이 열립니다.

`/login` 을 뺀 나머지는 `ShellRoute` 안에 있습니다. 메뉴 사이를 오갈 때 좌측
메뉴와 상단 바가 다시 만들어지지 않습니다.

## 4. 상태 표현

```dart
enum ViewState { idle, loading, success, error }
```

여기에 더해 `BaseViewModel` 이 `isBusy` 를 따로 가집니다.

**둘을 나눈 이유**: 목록을 이미 그린 상태에서 저장/삭제가 돌 때 `state` 를
loading 으로 바꾸면 화면이 통째로 스피너가 되어 방금까지 보던 표가 사라집니다.
관리자 화면에서는 표를 그대로 두고 버튼만 비활성으로 만드는 쪽이 맞습니다.

```dart
Future<void> load() => guard(() async { ... });        // 조회 -> state
Future<bool> delete(id) => runTask(() async { ... });  // 조작 -> isBusy
```

## 5. 의존성 주입

| 도구 | 담당 |
| --- | --- |
| **get_it** | Repository, UseCase, DioClient, 전역 세션 |
| **provider** | ViewModel - 화면 생명주기를 따라가고 나가면 dispose |

등록은 `core/di/injector.dart` 한 곳에서만 합니다.

`AdminSession` 만 예외로 get_it 과 provider 양쪽에 있습니다. 라우터가 만들어지는
시점에는 위젯 트리가 없어서 get_it 에서 꺼내야 하고, 화면은 provider 로 구독해야
합니다. 같은 인스턴스입니다.

## 6. 새 기능 추가 레시피

```
1. domain/entities/x.dart
2. domain/repositories/x_repository.dart      # abstract
3. domain/usecases/x_use_cases.dart           # 한 파일에 여러 UseCase
4. data/x_repository_impl.dart                # Dio 호출 + JSON->Entity
5. presentation/viewmodels/x_list_view_model.dart
6. presentation/views/x_list_view.dart
7. core/di/injector.dart 에 등록
8. core/router/{app_routes,app_router}.dart 에 경로 추가
9. core/widgets/admin_shell.dart 의 메뉴에 추가
10. docs/API.md(백엔드 저장소)에 사용한 엔드포인트 확인
```

## 7. 반응형

데스크톱 전용이지만 노트북 화면과 창 분할을 고려합니다.

- 1100px 미만에서 좌측 메뉴가 아이콘만 남깁니다. 240px 메뉴가 그대로 있으면
  표의 열이 잘립니다
- 지표 카드는 1080px 이상 4열, 아래는 2열
- 편집 폼은 720px 에서 자릅니다. 표는 자르지 않습니다 - 열이 많으면 넓을수록 좋습니다

## 8. 테스트

우선순위대로:

1. **ViewModel** - mock Repository 를 주입해 상태 전이와 호출 인자 검증
2. RepositoryImpl - JSON 매핑
3. Widget 테스트 - 표와 폼 정도

mock 은 `mocktail` 을 씁니다(코드 생성 불필요).

```bash
flutter analyze && flutter test
```

# Vercel 배포 가이드

관리자 콘솔을 Vercel에 배포하는 절차. 서비스 프론트엔드와 같은 방식이다.

## 사전 준비

**관리자 백엔드를 먼저 Railway에 올리고 공개 주소를 받아 둔다.** 그 주소가 없으면
빌드가 멈춘다(아래 3절 참고).

## 1. 프로젝트 생성

1. Vercel 대시보드에서 Add New -> Project
2. `admin-goodquestion-frontend` 저장소 선택
3. Framework Preset은 Other로 둔다. 저장소의 `vercel.json` 이 빌드 방법을 갖고 있다
4. Production Branch를 `develop` 으로 바꾼다. 팀이 `develop` 을 배포 기준으로 쓴다

## 2. 환경변수

Settings -> Environment Variables 에 넣는다.

```
API_BASE_URL=https://<Railway 관리자 백엔드 주소>/api/admin
```

**끝이 `/api/admin` 이어야 한다.** 백엔드의 기본 경로가 그것이고 앱은 뒤만 붙인다.
`/api` 로 끝나면 모든 요청이 404가 된다.

이 값 하나뿐이다. 관리자 콘솔은 소셜 로그인을 쓰지 않는다.

## 3. 빌드가 멈추는 경우

`tool/vercel_build.sh` 가 아래 셋을 검사하고 걸리면 빌드를 세운다.

| 검사 | 이유 |
| --- | --- |
| `API_BASE_URL` 이 비었는가 | 비우면 로컬 주소(127.0.0.1:8081)를 보는 앱이 배포된다 |
| `https` 인가 | HTTPS 페이지에서 http 요청은 브라우저가 mixed content로 막는다 |
| `/api/admin` 으로 끝나는가 | 아니면 모든 요청이 404 |

**조용히 지나가지 않고 빌드를 세우는 이유**: 이 값은 `String.fromEnvironment` 로
읽는 컴파일 시점 상수다. 잘못 박히면 브라우저에서 고칠 방법이 없고 다시 빌드하는
수밖에 없다. 배포 후 콘솔을 열어보고서야 알게 되느니 빌드에서 막는다.

## 4. 백엔드 CORS 열기

배포 주소가 나오면 Railway의 관리자 백엔드 환경변수에 그 주소를 넣는다.

```
CORS_ALLOWED_ORIGIN_PATTERNS=https://admin-goodquestion-frontend.vercel.app,https://admin-goodquestion-frontend-*-team-mugunghwa.vercel.app
```

**프리뷰 배포까지 패턴으로 넣는 이유**: Vercel은 커밋마다 주소가 바뀐다. 정확한
값을 미리 적을 수 없다. 팀 슬러그(`team-mugunghwa`)까지 넣는 것은 같은 이름으로
프로젝트를 만든 남의 Vercel 계정 주소가 걸리지 않게 하려는 것이다.

이걸 빠뜨리면 화면은 뜨는데 로그인부터 실패한다. 브라우저 콘솔에 CORS 오류가
찍히고 서버 로그에는 아무것도 남지 않는다.

## 5. 확인

1. 배포 주소를 연다. 로그인 화면이 떠야 한다
2. 시드 계정으로 로그인한다
3. 대시보드에 숫자가 채워지면 백엔드 연결까지 정상이다

숫자가 0이고 오류도 없다면 **DB가 서비스와 갈린 것**이다. Railway 관리자 백엔드의
`DB_URL` 이 기존 Postgres를 가리키는지 확인한다.

## 6. 검색 노출 차단

`vercel.json` 이 모든 경로에 `X-Robots-Tag: noindex, nofollow` 를 붙인다. 관리자
콘솔이 검색 결과에 뜰 이유가 없다.

주소를 아는 사람은 로그인 화면까지 올 수 있다. **접근 자체를 막으려면** Vercel의
Deployment Protection이나 팀 플랜의 접근 제어를 함께 쓴다.

## 로컬에서 배포 빌드 재현

```bash
API_BASE_URL=https://<주소>/api/admin bash tool/vercel_build.sh
```

`$HOME/flutter` 에 SDK를 clone하므로 처음 한 번은 오래 걸린다.

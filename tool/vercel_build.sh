#!/usr/bin/env bash
#
# Vercel 빌드 스크립트.
#
# Vercel 은 Flutter 런타임이 없어서 SDK 를 직접 받아 씁니다.
# 결과물인 build/web 을 정적 사이트로 서빙합니다. -> vercel.json
#
# 로컬에서 배포 빌드를 재현해 보려면:
#   API_BASE_URL=https://admin-goodquestion-backend-production.up.railway.app/api/admin \
#     bash tool/vercel_build.sh
set -euo pipefail

# 서비스 프론트엔드와 같은 값을 유지하세요. 버전이 갈리면 한쪽만 깨집니다.
FLUTTER_VERSION="3.44.9"
FLUTTER_HOME="$HOME/flutter"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

# Vercel 빌드 컨테이너는 clone 한 저장소의 소유자가 달라서 git 이
# "dubious ownership" 으로 거부합니다. flutter 명령이 내부에서 git 을 쓰기
# 때문에 이걸 안 해두면 SDK 인식 자체가 실패합니다.
git config --global --add safe.directory "$FLUTTER_HOME"

flutter --version
flutter pub get

# 관리자 백엔드 주소. Vercel 대시보드에 API_BASE_URL 을 등록하면 그 값이 우선합니다.
API_BASE_URL="${API_BASE_URL:-}"

# 프리뷰 배포(PR 마다 생기는 임시 주소)에는 기본값을 씁니다.
#
# Vercel 의 환경변수는 Production / Preview / Development 로 **따로** 걸립니다.
# API_BASE_URL 이 Production 에만 등록돼 있어서, PR 프리뷰는 값이 빈 채로
# 빌드에 들어와 여기서 통째로 멈췄습니다. 머지 전에 프리뷰로 눌러 보려는데
# 프리뷰가 안 뜨면 확인할 방법이 없어집니다.
#
# 프로덕션은 그대로 세웁니다. 잘못된 주소가 박힌 채 나가면 브라우저에서
# 고칠 방법이 없고 되돌리려면 다시 빌드해야 하는데, 프리뷰는 주소가 어차피
# 일회용이라 다시 밀면 그만입니다. 위험의 크기가 다르니 처방도 다릅니다.
#
# 서비스 프론트엔드(goodquestion-frontend)의 같은 스크립트는 애초에 기본값을
# 갖고 있습니다. 여기만 방침이 갈려 있던 것을 맞춥니다.
DEFAULT_API_BASE_URL="https://admin-goodquestion-backend.up.railway.app/api/admin"

if [ -z "$API_BASE_URL" ]; then
  if [ "${VERCEL_ENV:-}" = "production" ]; then
    cat >&2 <<'MSG'
API_BASE_URL 이 비어 있습니다.

관리자 콘솔은 백엔드 주소를 컴파일 시점에 박아 넣습니다. 비운 채로 빌드하면
브라우저에서 값을 넣어 고칠 방법이 없습니다. 다시 빌드하는 수밖에 없어서
빌드를 세웁니다.

Vercel 대시보드 -> Settings -> Environment Variables 에 등록하세요.
  API_BASE_URL=https://<관리자 백엔드 주소>/api/admin

**Production 뿐 아니라 Preview 에도 체크하세요.** 스코프가 갈려 있으면
PR 프리뷰만 다른 주소를 보게 됩니다.
MSG
    exit 1
  fi

  API_BASE_URL="$DEFAULT_API_BASE_URL"
  echo "API_BASE_URL 이 비어 있어 기본값을 씁니다 (VERCEL_ENV=${VERCEL_ENV:-미설정})" >&2
fi

# http 가 넘어오면 HTTPS 페이지라 브라우저가 mixed content 로 막습니다.
# 배포 후에 콘솔을 열어보고서야 알게 되느니 빌드를 세웁니다.
case "$API_BASE_URL" in
  https://*) ;;
  *) echo "API_BASE_URL 은 https 여야 합니다: $API_BASE_URL" >&2; exit 1 ;;
esac

# 경로 끝이 /api/admin 이 아니면 모든 요청이 404 가 됩니다. 백엔드의 기본
# 경로가 /api/admin 이고 앱은 그 뒤만 붙입니다.
case "$API_BASE_URL" in
  */api/admin) ;;
  *) echo "API_BASE_URL 은 /api/admin 으로 끝나야 합니다: $API_BASE_URL" >&2; exit 1 ;;
esac

echo "API_BASE_URL=$API_BASE_URL"

flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"

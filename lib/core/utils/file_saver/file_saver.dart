/// 받은 바이트를 사용자의 파일로 저장합니다.
///
/// 웹에서는 브라우저 다운로드로 이어지고, 그 밖의 환경(테스트 포함)에서는
/// 지원하지 않는다고 알립니다. 관리자 콘솔은 웹으로만 배포됩니다.
library;

export 'file_saver_unsupported.dart'
    if (dart.library.js_interop) 'file_saver_web.dart';

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// 브라우저 다운로드로 저장합니다.
///
/// Blob 주소를 단 링크를 만들어 대신 눌러 주는 방식입니다. 브라우저가 파일
/// 저장을 스크립트에 직접 열어 주지 않아서 이 우회가 표준 방법입니다.
void saveFile(String fileName, List<int> bytes, String mimeType) {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  // 주소를 돌려주지 않으면 탭이 닫힐 때까지 바이트가 메모리에 남습니다.
  web.URL.revokeObjectURL(url);
}

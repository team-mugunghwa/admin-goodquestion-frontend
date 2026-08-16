/// 웹이 아닌 환경의 대역. 테스트가 이 경로로 컴파일됩니다.
void saveFile(String fileName, List<int> bytes, String mimeType) {
  throw UnsupportedError('파일 저장은 웹 빌드에서만 지원합니다.');
}

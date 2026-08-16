/// 서버의 목록 응답 봉투.
///
/// 백엔드 `PageResponse` 와 짝입니다. 화면은 이걸 그대로 들고 페이지네이션을 그립니다.
///
/// [page] 는 0부터 시작합니다. 화면에 "1페이지"로 보이는 것이 여기서는 0입니다 -
/// 서버와 맞추는 쪽이 변환 실수를 줄입니다. 사람이 읽는 번호로 바꾸는 것은
/// 페이지네이션 위젯 한 곳에서만 합니다.
class PageResult<T> {
  const PageResult({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  const PageResult.empty()
    : content = const [],
      page = 0,
      size = 0,
      totalElements = 0,
      totalPages = 0;

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get isEmpty => content.isEmpty;
  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;

  /// DTO 목록을 Entity 목록으로 바꾸면서 페이지 정보는 그대로 둡니다.
  PageResult<R> map<R>(R Function(T item) transform) => PageResult<R>(
    content: content.map(transform).toList(),
    page: page,
    size: size,
    totalElements: totalElements,
    totalPages: totalPages,
  );

  static PageResult<T> fromJson<T>(
    Object? data,
    T Function(Map<String, dynamic> json) parseItem,
  ) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final rawContent = map['content'];
    return PageResult<T>(
      content: rawContent is List
          ? rawContent
                .whereType<Map<String, dynamic>>()
                .map(parseItem)
                .toList()
          : const [],
      page: (map['page'] as num?)?.toInt() ?? 0,
      size: (map['size'] as num?)?.toInt() ?? 0,
      totalElements: (map['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}

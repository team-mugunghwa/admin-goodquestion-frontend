import '../widgets/app_status_chip.dart';

/// 공지와 이용안내가 공유하는 노출 상태.
///
/// 두 feature 가 함께 쓰므로 core 에 둡니다. 한쪽에 두고 다른 쪽이 import 하면
/// feature 사이에 의존이 생기고, 나중에 공지를 걷어낼 때 이용안내가 함께 깨집니다.
enum ContentStatus {
  draft('DRAFT', '비공개', StatusTone.neutral),
  published('PUBLISHED', '공개', StatusTone.positive),
  archived('ARCHIVED', '보관', StatusTone.caution);

  const ContentStatus(this.code, this.label, this.tone);

  final String code;
  final String label;

  /// 배지 색. 화면마다 다른 색을 고르지 않도록 여기서 정합니다.
  final StatusTone tone;

  static ContentStatus fromCode(String? code) => ContentStatus.values.firstWhere(
    (status) => status.code == code,
    // 모르는 값이 오면 비공개로 봅니다. 서버가 상태를 늘렸을 때 화면이 죽는 대신
    // "안 보이는 것"으로 떨어지는 쪽이 안전합니다.
    orElse: () => ContentStatus.draft,
  );

  /// 필터 드롭다운용 표.
  static Map<ContentStatus, String> get labels => {
    for (final status in ContentStatus.values) status: status.label,
  };
}

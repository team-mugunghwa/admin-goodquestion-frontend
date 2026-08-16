import '../../../../core/domain/content_status.dart';

enum GuideCategory {
  basic('BASIC', '서비스 소개'),
  account('ACCOUNT', '계정/아이 프로필'),
  play('PLAY', '이야기 진행'),
  reward('REWARD', '별가루/행성'),
  trouble('TROUBLE', '문제 해결');

  const GuideCategory(this.code, this.label);

  final String code;
  final String label;

  static GuideCategory fromCode(String? code) => GuideCategory.values
      .firstWhere((c) => c.code == code, orElse: () => GuideCategory.basic);

  static Map<GuideCategory, String> get labels => {
    for (final category in GuideCategory.values) category: category.label,
  };
}

/// 이용안내 문서 한 편.
///
/// 목록과 상세를 나누지 않았습니다. 문서가 짧고 관리자 화면이 목록에서 바로
/// 펼쳐 편집하는 형태라, 본문까지 한 번에 받는 쪽이 요청도 적고 화면도 단순합니다.
class Guide {
  const Guide({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.displayOrder,
    required this.status,
    this.updatedAt,
  });

  final String id;
  final GuideCategory category;
  final String title;
  final String content;

  /// 카테고리 안에서의 노출 순서. 작을수록 위입니다.
  final int displayOrder;
  final ContentStatus status;
  final DateTime? updatedAt;
}

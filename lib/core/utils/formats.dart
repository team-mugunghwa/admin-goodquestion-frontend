import 'package:intl/intl.dart';

/// 표기 규칙을 한곳에 모읍니다.
///
/// 화면마다 `DateFormat` 을 새로 만들면 어떤 표는 `2026-08-16`, 다른 표는
/// `2026.08.16` 이 됩니다. 같은 데이터를 다른 모양으로 보여주는 것만큼
/// 관리자 화면을 지저분하게 만드는 것이 없습니다.
abstract final class Formats {
  static final DateFormat _date = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTime = DateFormat('yyyy-MM-dd HH:mm');
  static final NumberFormat _count = NumberFormat('#,###');

  /// 표의 날짜 열. 시각이 필요 없는 곳에 씁니다.
  static String date(DateTime? value) =>
      value == null ? '-' : _date.format(value.toLocal());

  /// 상세 화면과 로그. 몇 시에 있었는지가 중요한 곳.
  static String dateTime(DateTime? value) =>
      value == null ? '-' : _dateTime.format(value.toLocal());

  /// 자릿수 구분. 사용자 수처럼 큰 숫자에 씁니다.
  static String count(num? value) => value == null ? '-' : _count.format(value);

  /// "3분 전"처럼 상대 시간으로 씁니다.
  ///
  /// 감사 로그와 최근 활동에만 씁니다. 표의 날짜 열에 쓰면 정렬 순서를 눈으로
  /// 확인할 수 없게 됩니다 - "어제"와 "2일 전" 사이에 무엇이 있었는지 알 수 없습니다.
  static String relative(DateTime? value) {
    if (value == null) return '-';
    final diff = DateTime.now().difference(value.toLocal());
    if (diff.inSeconds < 60) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return _date.format(value.toLocal());
  }

  /// 긴 본문을 목록에서 한 줄로 줄입니다. 줄바꿈은 공백으로 바꿉니다 -
  /// 그대로 두면 `maxLines: 1` 이라도 첫 줄만 보이고 나머지가 잘려 뜻이 달라집니다.
  static String oneLine(String? value, {int max = 80}) {
    if (value == null || value.isEmpty) return '-';
    final flat = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= max ? flat : '${flat.substring(0, max)}...';
  }
}

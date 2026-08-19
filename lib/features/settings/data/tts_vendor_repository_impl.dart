import '../../../core/error/exceptions.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/entities/tts_vendor.dart';
import '../domain/repositories/tts_vendor_repository.dart';

class TtsVendorRepositoryImpl implements TtsVendorRepository {
  const TtsVendorRepositoryImpl(this._client);

  final DioClient _client;

  /// `AppConfig.apiBaseUrl` 이 이미 `/api/admin` 까지 들고 있으므로 여기서는
  /// 그 뒤만 적습니다.
  static const String _path = '/settings/tts-vendor';

  @override
  Future<TtsVendorSetting> getTtsVendor() => _guard(
    () => _client.get(_path, parse: (data) => _toSetting(_asMap(data))),
  );

  @override
  Future<TtsVendorSetting> updateTtsVendor(TtsVendor vendor) => _guard(
    () => _client.put(
      _path,
      body: {'vendor': vendor.code},
      // 변경 응답도 조회와 같은 모양이라 그대로 화면에 씁니다. 저장 직후 다시
      // 조회하면 그 사이 다른 관리자가 바꾼 값을 내 조작 결과로 오해합니다.
      parse: (data) => _toSetting(_asMap(data)),
    ),
  );

  static TtsVendorSetting _toSetting(Map<String, dynamic> json) =>
      TtsVendorSetting(
        vendor: TtsVendor.fromCode(json['vendor'] as String?),
        // 서버가 UTC 로 줍니다. 여기서 현지 시각으로 바꿔 두지 않으면 화면마다
        // 아홉 시간씩 어긋납니다.
        updatedAt: DateTime.tryParse(
          json['updatedAt'] as String? ?? '',
        )?.toLocal(),
      );

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw const ParseException();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException catch (e) {
      throw Failure.fromException(e);
    }
  }
}

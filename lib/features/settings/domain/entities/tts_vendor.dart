/// 음성 합성에 쓰는 벤더.
///
/// 값이 셋뿐이고 서버와는 문자열 코드로 주고받습니다. 코드를 그대로 화면에 뿌리면
/// 관리자가 무엇을 고르는 것인지 알 수 없어, 무슨 모델이 도는지와 언제 쓰는지를
/// 여기 함께 둡니다. 설명을 화면 쪽에 흩어 놓으면 벤더를 늘릴 때 빠뜨립니다.
enum TtsVendor {
  openai(
    code: 'OPENAI',
    label: 'OpenAI',
    model: 'gpt-4o-mini-tts',
    envKey: 'TTS_API_KEY (없으면 LLM_API_KEY)',
    description: '기본값입니다. 키만 들어 있으면 언제든 씁니다.',
  ),
  gemini(
    code: 'GEMINI',
    label: 'Gemini',
    model: 'gemini-2.5-flash-preview-tts',
    envKey: 'GEMINI_API_KEY',
    description: '미리 만들어 둔 음성과 화자가 같습니다. 시연에 씁니다.',
  ),
  chirp3(
    code: 'CHIRP3',
    label: 'Chirp 3',
    model: 'Cloud TTS Chirp 3: HD',
    envKey: 'GOOGLE_CLOUD_API_KEY',
    description: '월 100만 자까지 무료입니다. 테스트 기간에 씁니다.',
  );

  const TtsVendor({
    required this.code,
    required this.label,
    required this.model,
    required this.envKey,
    required this.description,
  });

  /// 서버와 주고받는 값. 화면에는 [label] 을 보여줍니다.
  final String code;
  final String label;

  /// 실제로 도는 모델 이름. 목소리가 왜 달라지는지는 결국 이것이 정합니다.
  final String model;

  /// 이 벤더의 키가 들어 있어야 하는 **본 서버**의 환경변수 이름.
  ///
  /// 콘솔에서는 키를 바꿀 수 없습니다. 그런데도 이름을 들고 있는 이유는, 키가 없는
  /// 벤더로 바꾸면 합성이 통째로 멈추기 때문입니다. 어디를 봐야 하는지 모르면
  /// 되돌리는 것 말고는 할 수 있는 일이 없습니다.
  final String envKey;

  /// 언제 이 벤더를 고르는지 한 줄로.
  final String description;

  /// 모르는 코드는 기본값으로 봅니다. 서버가 벤더를 늘렸을 때 화면이 죽는 대신
  /// "기본값이 걸려 있다"로 떨어지는 쪽이 안전합니다 - 이 화면은 값을 되돌리는
  /// 곳이기도 해서, 화면이 안 뜨면 되돌릴 방법까지 같이 사라집니다.
  static TtsVendor fromCode(String? code) => TtsVendor.values.firstWhere(
    (vendor) => vendor.code == code,
    orElse: () => TtsVendor.openai,
  );
}

/// 지금 걸려 있는 벤더와 그 값이 마지막으로 바뀐 시각.
///
/// 조회와 변경이 같은 모양을 돌려주므로 한 타입으로 받습니다. 변경 응답을 그대로
/// 화면에 쓰면 저장한 뒤 다시 조회하지 않아도 시각이 맞습니다.
class TtsVendorSetting {
  const TtsVendorSetting({required this.vendor, this.updatedAt});

  final TtsVendor vendor;

  /// 서버가 한 번도 기록한 적이 없으면 비어 있을 수 있습니다.
  final DateTime? updatedAt;
}

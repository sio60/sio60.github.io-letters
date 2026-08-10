/// ─────────────────────────────────────────────────────────────
///  여기만 고치면 됩니다.
/// ─────────────────────────────────────────────────────────────
library;

class LetterConfig {
  const LetterConfig._();

  /// 편지를 받을 사람 이름. 조사 없이 이름만 적으세요.
  /// 편지 첫 줄에는 "<이름>에게," 로 나갑니다.
  static const String recipientName = '재희';

  /// 편지를 보내는 사람 이름 (편지 끝에 표시됩니다).
  static const String senderName = '유나';

  /// 앱 제목.
  static const String appTitle = '66일의 편지';

  /// 1일차 편지가 열리는 날짜 = 재희에게 주는 날.
  /// 이 날짜부터 하루에 한 장씩 자동으로 해금됩니다.
  /// (2026년 10월 10일 1일차 → 12월 14일 66일차)
  static final DateTime startDate = DateTime(2026, 10, 10);

  /// ⚠️ 원고 쓰는 동안 날짜 상관없이 전부 열어두는 스위치.
  ///
  /// 켜져 있으면 앱 위쪽에 검은 띠로 경고가 뜹니다.
  /// **재희에게 주기 전에 반드시 false 로 바꾸세요.**
  static const bool unlockAllForPreview = true;

  /// 총 편지 수. letters/letters.txt 의 편지 개수와 맞춰주세요.
  /// 66장이면 마지막 편지가 만난 지 365일에 열립니다.
  static const int totalDays = 66;

  /// 마지막 편지까지 다 읽은 뒤 보여줄 한 줄.
  static const String finaleMessage = '365일, 전부 전했어. 고마워.';

  // ── 첫 화면(커버) 문구 ──────────────────────────────────────

  /// 맨 위 작은 라벨.
  static const String coverLabel = '1ST ANNIVERSARY';

  /// 큰 글씨 위에 붙는 한 줄.
  static const String coverLead = '우리 만난 지';

  /// 표지에서 제일 크게 보이는 문구.
  static const String coverHeadline = '벌써 1년';

  /// 커버에서 편지 목록으로 넘어가는 버튼.
  static const String coverAction = '편지 보러 가기';
}

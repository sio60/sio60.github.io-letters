import '../config.dart';

/// 편지 한 장.
class Letter {
  const Letter({required this.day, required this.body});

  /// 1부터 시작하는 일차.
  final int day;

  /// 편지 전문. 제목은 따로 두지 않습니다.
  final String body;

  /// 편지에 담긴 날. 실제 작성·수정 시각이나 공개 날짜를 뜻하지 않습니다.
  DateTime get entryDate {
    final s = LetterConfig.entryStartDate;
    return DateTime(s.year, s.month, s.day + (day - 1));
  }

  /// 이 편지가 열리는 날짜 (자정 기준).
  DateTime get unlockDate {
    final s = LetterConfig.startDate;
    return DateTime(s.year, s.month, s.day + (day - 1));
  }
}

/// 편지의 현재 상태.
enum LetterStatus {
  /// 아직 열리지 않음.
  locked,

  /// 오늘 막 열린 편지.
  today,

  /// 이전에 열렸고 이미 읽음.
  read,

  /// 이전에 열렸지만 아직 안 읽음.
  unread,
}

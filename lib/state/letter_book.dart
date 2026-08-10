import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/letters.dart';
import '../models/letter.dart';

const String _readKey = 'read_days';

/// 편지 목록 + 해금 상태 + 읽음 표시를 들고 있는 앱 상태.
class LetterBook extends ChangeNotifier {
  LetterBook._(this._prefs, this.letters, this._read, this._now, this._unlockAll) {
    // 자정을 넘겨 새 편지가 열리는 순간을 놓치지 않기 위한 주기적 확인.
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      final now = unlockedCount;
      if (now != _lastUnlocked) {
        _lastUnlocked = now;
        notifyListeners();
      }
    });
    _lastUnlocked = unlockedCount;
  }

  /// [clock] 과 [unlockAll] 은 테스트에서 특정 상황을 흉내 낼 때만 넘깁니다.
  static Future<LetterBook> load({DateTime Function()? clock, bool? unlockAll}) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_readKey) ?? const <String>[];
    return LetterBook._(
      prefs,
      loadLetters(),
      saved.map(int.tryParse).whereType<int>().toSet(),
      clock ?? DateTime.now,
      unlockAll ?? LetterConfig.unlockAllForPreview,
    );
  }

  final SharedPreferences _prefs;
  final List<Letter> letters;
  final Set<int> _read;
  final DateTime Function() _now;
  final bool _unlockAll;

  late final Timer _ticker;
  late int _lastUnlocked;

  int get totalDays => letters.length;

  /// 지금까지 열린 편지 수. 시작일 전이면 0.
  int get unlockedCount {
    if (_unlockAll) return totalDays;
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final start = LetterConfig.startDate;
    final elapsed = today.difference(DateTime(start.year, start.month, start.day)).inDays;
    return (elapsed + 1).clamp(0, totalDays);
  }

  bool get hasStarted => unlockedCount > 0;

  bool get isComplete => unlockedCount >= totalDays;

  /// 열린 편지 중 아직 안 읽은 가장 이른 편지.
  ///
  /// 상대가 며칠 건너뛰고 들어와도 밀린 편지부터 순서대로 읽게 하기 위한 기준입니다.
  Letter? get oldestUnread {
    for (final letter in letters.take(unlockedCount)) {
      if (!_read.contains(letter.day)) return letter;
    }
    return null;
  }

  /// 이 편지가 오늘 열린 편지인지.
  bool isTodays(Letter letter) => _isToday(letter.unlockDate);

  /// 열렸지만 아직 안 읽은 편지 수.
  int get unreadCount =>
      letters.take(unlockedCount).where((l) => !_read.contains(l.day)).length;

  int get readCount => letters.take(unlockedCount).where((l) => _read.contains(l.day)).length;

  bool isUnlocked(Letter letter) => letter.day <= unlockedCount;

  bool isRead(Letter letter) => _read.contains(letter.day);

  LetterStatus statusOf(Letter letter) {
    if (!isUnlocked(letter)) return LetterStatus.locked;
    if (_isToday(letter.unlockDate) && !isRead(letter)) return LetterStatus.today;
    return isRead(letter) ? LetterStatus.read : LetterStatus.unread;
  }

  Future<void> markRead(Letter letter) async {
    if (!_read.add(letter.day)) return;
    notifyListeners();
    await _prefs.setStringList(_readKey, _read.map((d) => '$d').toList());
  }

  /// 다음 편지가 열리기까지 남은 시간. 더 열릴 편지가 없으면 null.
  Duration? get timeUntilNext {
    if (isComplete) return null;
    final next = letters[unlockedCount].unlockDate;
    final remaining = next.difference(_now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 시작일까지 남은 일수 (아직 시작 전일 때).
  int get daysUntilStart {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final start = LetterConfig.startDate;
    return DateTime(start.year, start.month, start.day).difference(today).inDays;
  }

  bool _isToday(DateTime date) {
    final now = _now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }
}

/// 위젯 트리 어디서든 LetterBook 을 꺼내 쓰기 위한 스코프.
class LetterBookScope extends InheritedNotifier<LetterBook> {
  const LetterBookScope({super.key, required LetterBook book, required super.child})
      : super(notifier: book);

  static LetterBook of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LetterBookScope>();
    assert(scope != null, 'LetterBookScope 를 찾을 수 없습니다.');
    return scope!.notifier!;
  }
}

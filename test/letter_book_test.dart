import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jhjhjhjh/config.dart';
import 'package:jhjhjhjh/data/codec.dart';
import 'package:jhjhjhjh/data/letters.dart';
import 'package:jhjhjhjh/models/letter.dart';
import 'package:jhjhjhjh/screens/cover_screen.dart';
import 'package:jhjhjhjh/screens/home_screen.dart';
import 'package:jhjhjhjh/state/letter_book.dart';
import 'package:jhjhjhjh/theme.dart';
import 'package:jhjhjhjh/util/korean_text.dart';
import 'package:jhjhjhjh/screens/letter_screen.dart';

/// 시작일 기준으로 며칠 뒤를 흉내 내는 시계.
DateTime Function() clockAt(DateTime day) =>
    () => DateTime(day.year, day.month, day.day, 9);
DateTime Function() dayOfLetter(int day) =>
    clockAt(LetterConfig.startDate.add(Duration(days: day - 1)));

/// 날짜 로직을 검증할 때는 미리보기 스위치를 꺼두고 확인합니다.
Future<LetterBook> bookOn(DateTime Function() clock) =>
    LetterBook.load(clock: clock, unlockAll: false);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('데이터', () {
    test('난독화는 원문을 그대로 복원한다', () {
      const plain = '오늘도 잘 지냈어?\n\n줄바꿈도 그대로.';
      expect(deobfuscate(obfuscate(plain)), plain);
      expect(obfuscate(plain), isNot(contains('오늘도')));
    });

    test('원고에서 설정한 일수만큼 편지를 읽어온다', () {
      final letters = loadLetters();
      expect(letters, hasLength(LetterConfig.totalDays));
      expect(letters.first.day, 1);
      expect(letters.last.day, LetterConfig.totalDays);
      expect(letters.every((l) => l.body.isNotEmpty), isTrue);
    });

    test('이미 쓴 편지에는 실제 본문이 들어 있다', () {
      final letters = loadLetters();
      expect(letters[0].body, contains('300일'));
      expect(letters[1].body, contains('택시'));
      expect(letters[2].body, contains('연락'));

      // 아직 안 쓴 편지는 "글감:" 으로 시작합니다. 원고를 채울수록 줄어듭니다.
      final unwritten = letters.where((l) => l.body.startsWith('글감:')).length;
      expect(unwritten, lessThan(letters.length));
    });
  });

  group('줄바꿈', () {
    const joiner = '⁠';
    String glued(String word) => word.split('').join(joiner);

    test('단어 안쪽은 묶고 띄어쓰기와 줄바꿈은 그대로 둔다', () {
      expect(keepWordsWhole('마음에 걸렸어'), '${glued('마음에')} ${glued('걸렸어')}');
      expect(keepWordsWhole('한 글자'), '한 ${glued('글자')}');
      expect(keepWordsWhole('위\n아래'), '위\n${glued('아래')}');
    });

    test('보이는 글자는 그대로다', () {
      const body = '오늘 우리 300일이야\n그동안 진짜 많은 일이 있었는데';
      expect(keepWordsWhole(body).replaceAll(joiner, ''), body);
    });
  });

  group('날짜 계산', () {
    test('편지에 담긴 날은 공개일과 별도로 하루씩 이어진다', () {
      final letters = loadLetters();
      expect(letters[0].entryDate, DateTime(2026, 8, 5));
      expect(letters[1].entryDate, DateTime(2026, 8, 6));
      expect(letters[2].entryDate, DateTime(2026, 8, 7));
      expect(letters[27].entryDate, DateTime(2026, 9, 1));
      expect(letters[65].entryDate, DateTime(2026, 10, 9));
      expect(letters[0].unlockDate, DateTime(2026, 10, 10));
    });

    test('N일차 편지는 시작일로부터 N-1일 뒤에 열린다', () {
      final letters = loadLetters();
      final start = LetterConfig.startDate;
      expect(
        letters[0].unlockDate,
        DateTime(start.year, start.month, start.day),
      );
      expect(
        letters[64].unlockDate,
        DateTime(start.year, start.month, start.day + 64),
      );
    });
  });

  group('해금', () {
    test('시작 전에는 아무것도 열리지 않는다', () async {
      final book = await bookOn(
        clockAt(LetterConfig.startDate.subtract(const Duration(days: 3))),
      );
      expect(book.unlockedCount, 0);
      expect(book.hasStarted, isFalse);
      expect(book.daysUntilStart, 3);
      expect(book.oldestUnread, isNull);
      book.dispose();
    });

    test('1일차 당일에는 한 장만 열린다', () async {
      final book = await bookOn(dayOfLetter(1));
      expect(book.unlockedCount, 1);
      expect(book.statusOf(book.letters[0]), LetterStatus.today);
      expect(book.statusOf(book.letters[1]), LetterStatus.locked);
      book.dispose();
    });

    test('6일차에는 여섯 장이 열리고 밀린 편지부터 안내한다', () async {
      final book = await bookOn(dayOfLetter(6));
      expect(book.unlockedCount, 6);
      expect(book.unreadCount, 6);
      expect(book.oldestUnread?.day, 1);
      expect(book.isTodays(book.letters[5]), isTrue);
      expect(book.isTodays(book.letters[0]), isFalse);
      book.dispose();
    });

    test('미리보기 스위치를 켜면 시작 전이어도 전부 열린다', () async {
      final clock = clockAt(
        LetterConfig.startDate.subtract(const Duration(days: 30)),
      );
      final preview = await LetterBook.load(clock: clock, unlockAll: true);
      expect(preview.unlockedCount, LetterConfig.totalDays);
      expect(preview.hasStarted, isTrue);
      preview.dispose();
    });

    test('마지막 날 이후로는 전체 장수에서 멈춘다', () async {
      final book = await bookOn(dayOfLetter(LetterConfig.totalDays));
      expect(book.unlockedCount, LetterConfig.totalDays);
      expect(book.isComplete, isTrue);
      expect(book.timeUntilNext, isNull);

      final later = await bookOn(dayOfLetter(LetterConfig.totalDays + 100));
      expect(later.unlockedCount, LetterConfig.totalDays);
      book.dispose();
      later.dispose();
    });
  });

  group('읽음 표시', () {
    test('열린 편지를 읽으면 read 로 바뀐다', () async {
      final book = await bookOn(dayOfLetter(6));
      final first = book.letters[0];

      expect(book.statusOf(first), LetterStatus.unread);
      await book.markRead(first);
      expect(book.statusOf(first), LetterStatus.read);
      expect(book.oldestUnread?.day, 2);
      book.dispose();
    });

    test('다시 열어도 유지된다', () async {
      final first = await bookOn(dayOfLetter(6));
      await first.markRead(first.letters[0]);
      first.dispose();

      final second = await bookOn(dayOfLetter(6));
      expect(second.isRead(second.letters[0]), isTrue);
      second.dispose();
    });
  });

  group('편지 날짜 표시', () {
    for (final day in [1, 2, 3]) {
      testWidgets('$day일차의 공개일과 본문 아래 날짜를 구분한다', (tester) async {
        tester.view
          ..devicePixelRatio = 1.0
          ..physicalSize = const Size(320, 840);
        addTearDown(tester.view.reset);
        final book = await bookOn(dayOfLetter(3));
        await tester.pumpWidget(
          LetterBookScope(
            book: book,
            child: MaterialApp(
              theme: buildTheme(),
              home: LetterScreen(letter: book.letters[day - 1]),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('공개일 2026.10.${day + 9}'), findsOneWidget);
        final footer = find.byKey(const ValueKey('letter-entry-date'));
        expect(footer, findsOneWidget);
        expect(tester.widget<Text>(footer).data, '2026.08.0${day + 4}');
        await tester.ensureVisible(footer);
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(footer).dy,
          greaterThan(
            tester.getBottomLeft(find.text(LetterConfig.senderName)).dy,
          ),
        );
        final dateRect = tester.getRect(footer);
        expect(dateRect.left, greaterThanOrEqualTo(0));
        expect(dateRect.right, lessThanOrEqualTo(320));
        expect(dateRect.bottom, lessThanOrEqualTo(840));
        expect(tester.takeException(), isNull);
        book.dispose();
      });
    }
  });

  group('출석형 메인 화면', () {
    Future<void> pumpHome(
      WidgetTester tester,
      LetterBook book, {
      bool legacyCover = false,
    }) async {
      await tester.pumpWidget(
        LetterBookScope(
          book: book,
          child: MaterialApp(
            theme: buildTheme(),
            home: legacyCover ? const CoverScreen() : const HomeScreen(),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/chiikawa-official-artwork.webp'),
          tester.element(find.byType(HomeScreen)),
        ),
      );
      await tester.pumpAndSettle();
    }

    void expectStatus(WidgetTester tester, String message, double progress) {
      final label = find.byKey(const ValueKey('home-unlock-message'));
      expect(label, findsOneWidget);
      final text = tester.widget<Text>(label).data!;
      expect(text.replaceAll(RegExp(r'\s+'), ' ').trim(), message);
      final indicator = find.byKey(const ValueKey('home-progress'));
      expect(indicator, findsOneWidget);
      expect(
        tester.widget<LinearProgressIndicator>(indicator).value,
        closeTo(progress, 0.000001),
      );
      expect(tester.takeException(), isNull);
    }

    testWidgets('시작 전에는 첫 편지를 기다리고 진행률은 0이다', (tester) async {
      final book = await bookOn(clockAt(DateTime(2026, 10, 9)));
      try {
        await pumpHome(tester, book);
        expectStatus(tester, '첫 편지를 기다리고 있어요', 0);
        expect(book.unlockedCount, 0);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        book.dispose();
      }
    });

    for (final day in [3, 4]) {
      testWidgets('$day일차에는 열린 장수로 문구와 진행률을 표시한다', (tester) async {
        final book = await bookOn(clockAt(DateTime(2026, 10, day + 9)));
        try {
          await pumpHome(tester, book);
          expectStatus(tester, '$day일차 편지가 열렸어요', day / LetterConfig.totalDays);
          await book.markRead(book.letters.first);
          await tester.pumpAndSettle();
          expectStatus(tester, '$day일차 편지가 열렸어요', day / LetterConfig.totalDays);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          book.dispose();
        }
      });
    }

    testWidgets('자정이 지나면 3일차에서 4일차로 안내가 갱신된다', (tester) async {
      var now = DateTime(2026, 10, 12, 23, 59, 50);
      final book = await LetterBook.load(clock: () => now, unlockAll: false);
      try {
        await pumpHome(tester, book);
        expectStatus(tester, '3일차 편지가 열렸어요', 3 / book.totalDays);
        now = DateTime(2026, 10, 13, 0, 0, 10);
        await tester.pump(const Duration(seconds: 20));
        await tester.pumpAndSettle();
        expectStatus(tester, '4일차 편지가 열렸어요', 4 / book.totalDays);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        book.dispose();
      }
    });

    testWidgets('66일차에는 읽지 않은 편지가 있어도 모두 열렸다고 표시한다', (tester) async {
      final book = await bookOn(dayOfLetter(66));
      try {
        await pumpHome(tester, book);
        expect(book.unreadCount, 66);
        expectStatus(tester, '모든 편지가 열렸어요', 1);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        book.dispose();
      }
    });

    testWidgets('기존 표지 진입점도 별도 표지 없이 메인 화면을 보여준다', (tester) async {
      final book = await bookOn(dayOfLetter(3));
      try {
        await pumpHome(tester, book, legacyCover: true);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('cover-enter')), findsNothing);
        expectStatus(tester, '3일차 편지가 열렸어요', 3 / book.totalDays);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        book.dispose();
      }
    });

    testWidgets('카드로 읽은 편지는 메인을 다시 불러와도 읽음 상태를 유지한다', (tester) async {
      final book = await bookOn(dayOfLetter(3));
      try {
        await pumpHome(tester, book);
        final firstCard = find.byKey(const ValueKey('letter-day-1'));
        await tester.scrollUntilVisible(firstCard, 180);
        await tester.tap(firstCard);
        await tester.pumpAndSettle();
        expect(find.byType(LetterScreen), findsOneWidget);
        expect(
          tester.widget<LetterScreen>(find.byType(LetterScreen)).letter.day,
          1,
        );
        expect(book.isRead(book.letters.first), isTrue);
        await tester.tap(find.text('편지 모음'));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        book.dispose();
      }

      final reloaded = await bookOn(dayOfLetter(3));
      try {
        await pumpHome(tester, reloaded);
        expect(reloaded.isRead(reloaded.letters.first), isTrue);
        expect(reloaded.readCount, 1);
        expect(reloaded.unlockedCount, 3);
        expect(reloaded.oldestUnread?.day, 2);
        expectStatus(tester, '3일차 편지가 열렸어요', 3 / reloaded.totalDays);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        reloaded.dispose();
      }
    });
  });
}

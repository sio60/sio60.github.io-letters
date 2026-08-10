import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:jhjhjhjh/widgets/speech_bubble.dart';

/// 시작일 기준으로 며칠 뒤를 흉내 내는 시계.
DateTime Function() clockAt(DateTime day) => () => DateTime(day.year, day.month, day.day, 9);
DateTime Function() dayOfLetter(int day) =>
    clockAt(LetterConfig.startDate.add(Duration(days: day - 1)));

/// 날짜 로직을 검증할 때는 미리보기 스위치를 꺼두고 확인합니다.
Future<LetterBook> bookOn(DateTime Function() clock) =>
    LetterBook.load(clock: clock, unlockAll: false);

void main() {
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
      expect(letters[2].body, contains('연락 방법'));

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
    test('N일차 편지는 시작일로부터 N-1일 뒤에 열린다', () {
      final letters = loadLetters();
      final start = LetterConfig.startDate;
      expect(letters[0].unlockDate, DateTime(start.year, start.month, start.day));
      expect(letters[64].unlockDate, DateTime(start.year, start.month, start.day + 64));
    });
  });

  group('해금', () {
    test('시작 전에는 아무것도 열리지 않는다', () async {
      final book = await bookOn(clockAt(LetterConfig.startDate.subtract(const Duration(days: 3))));
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
      final clock = clockAt(LetterConfig.startDate.subtract(const Duration(days: 30)));
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

  group('표지', () {
    Future<void> pumpCover(WidgetTester tester, LetterBook book) async {
      await tester.pumpWidget(
        LetterBookScope(
          book: book,
          child: MaterialApp(theme: buildTheme(), home: const CoverScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('1주년 라벨·날짜 카운트·하트 말풍선·캐릭터가 나온다', (tester) async {
      final book = await bookOn(dayOfLetter(1));
      await pumpCover(tester, book);

      expect(find.text(LetterConfig.coverLabel), findsOneWidget);
      expect(find.text(LetterConfig.coverLead), findsOneWidget);
      expect(find.text(LetterConfig.coverHeadline), findsOneWidget);

      // 말풍선 안에는 하트만 있고 글자는 없습니다.
      expect(
        find.descendant(of: find.byType(SpeechBubble), matching: find.byType(Text)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(SpeechBubble),
          matching: find.byIcon(Icons.favorite_rounded),
        ),
        findsOneWidget,
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, 'assets/yuna.png');
      book.dispose();
    });

    // 상대는 대부분 휴대폰으로 링크를 엽니다. 좁은 화면에서 글자가 잘리거나
    // 버튼이 캐릭터에 겹치지 않는지 확인합니다.
    for (final size in const [Size(375, 812), Size(360, 640)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()} 화면에 들어간다', (tester) async {
        tester.view
          ..devicePixelRatio = 1.0
          ..physicalSize = size;
        addTearDown(tester.view.reset);

        final book = await bookOn(dayOfLetter(1));
        await pumpCover(tester, book);
        expect(tester.takeException(), isNull);

        for (final text in [
          LetterConfig.coverLabel,
          LetterConfig.coverLead,
          LetterConfig.coverHeadline,
        ]) {
          final rect = tester.getRect(find.text(text));
          expect(rect.left, greaterThanOrEqualTo(0), reason: '"$text" 왼쪽이 잘림');
          expect(rect.right, lessThanOrEqualTo(size.width), reason: '"$text" 오른쪽이 잘림');
        }

        final button = tester.getRect(find.byType(FilledButton));
        final bubble = tester.getRect(find.byType(SpeechBubble));
        expect(button.bottom, lessThan(bubble.top), reason: '버튼이 캐릭터와 겹침');
        book.dispose();
      });
    }

    testWidgets('편지 목록으로 넘어간다', (tester) async {
      final book = await bookOn(dayOfLetter(1));
      await pumpCover(tester, book);

      await tester.tap(find.text(LetterConfig.coverAction));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('전체 편지'), findsOneWidget);
      book.dispose();
    });
  });

  group('편지 목록', () {
    Future<void> pumpHome(WidgetTester tester, LetterBook book) async {
      await tester.pumpWidget(
        LetterBookScope(
          book: book,
          child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('시작 전에는 남은 일수를 알려준다', (tester) async {
      final book = await bookOn(clockAt(LetterConfig.startDate.subtract(const Duration(days: 7))));
      await pumpHome(tester, book);

      expect(find.text('아직 시작 전이야'), findsOneWidget);
      expect(find.text('7일 뒤에 첫 번째 편지가 열려.'), findsOneWidget);
      expect(find.text('0 / ${LetterConfig.totalDays}'), findsOneWidget);
      book.dispose();
    });

    testWidgets('1일차 당일에는 오늘의 편지를 안내한다', (tester) async {
      final book = await bookOn(dayOfLetter(1));
      await pumpHome(tester, book);

      expect(find.text(LetterConfig.appTitle), findsOneWidget);
      expect(find.text(LetterConfig.recipientName), findsOneWidget);
      expect(find.text('오늘의 편지가 도착했어'), findsOneWidget);
      expect(find.text('열어보기'), findsOneWidget);
      expect(find.text('1 / ${LetterConfig.totalDays}'), findsOneWidget);
      book.dispose();
    });

    testWidgets('며칠 밀렸으면 가장 이른 편지부터 안내한다', (tester) async {
      final book = await bookOn(dayOfLetter(6));
      await pumpHome(tester, book);

      expect(find.text('1일차 편지를 아직 안 읽었어'), findsOneWidget);
      expect(find.text('1일차 · 뒤이어 읽을 편지가 5장 더 있어.'), findsOneWidget);
      expect(find.text('6 / ${LetterConfig.totalDays}'), findsOneWidget);
      book.dispose();
    });

    testWidgets('다 읽었으면 마지막 인사를 보여준다', (tester) async {
      final book = await bookOn(dayOfLetter(LetterConfig.totalDays));
      for (final letter in book.letters) {
        await book.markRead(letter);
      }
      await pumpHome(tester, book);

      expect(find.text('편지는 여기까지야'), findsOneWidget);
      expect(find.text(LetterConfig.finaleMessage), findsOneWidget);
      book.dispose();
    });
  });
}

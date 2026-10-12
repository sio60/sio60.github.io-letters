import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jhjhjhjh/config.dart';
import 'package:jhjhjhjh/main.dart' show LetterApp;
import 'package:jhjhjhjh/screens/cover_screen.dart';
import 'package:jhjhjhjh/screens/home_screen.dart';
import 'package:jhjhjhjh/screens/letter_screen.dart';
import 'package:jhjhjhjh/state/letter_book.dart';
import 'package:jhjhjhjh/theme.dart';

const _officialArtwork = 'assets/chiikawa-official-artwork.webp';

Future<void> _expectPlainLetter(WidgetTester tester, int day) async {
  final screen = find.byType(LetterScreen);
  expect(screen, findsOneWidget);
  expect(tester.widget<LetterScreen>(screen).letter.day, day);
  expect(
    find.descendant(of: screen, matching: find.byType(Image)),
    findsNothing,
  );
  final date = find.byKey(const ValueKey('letter-entry-date'));
  expect(date, findsOneWidget);
  expect(tester.widget<Text>(date).data, '2026.08.0${day + 4}');
  await tester.ensureVisible(date);
  await tester.pumpAndSettle();
  expect(
    tester.getRect(date).top,
    greaterThan(tester.getRect(find.text(LetterConfig.senderName)).bottom),
  );
  expect(tester.takeException(), isNull);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('출석형 메인 반응형 화면', () {
    for (final size in const [Size(320, 568), Size(390, 840), Size(760, 900)]) {
      testWidgets('${size.width.toInt()}px 메인·잠금·66장 스크롤·편지 왕복', (
        tester,
      ) async {
        tester.view
          ..devicePixelRatio = 1.0
          ..physicalSize = size;
        addTearDown(tester.view.reset);
        final book = await LetterBook.load(
          clock: () => DateTime(2026, 10, 12, 9),
          unlockAll: false,
        );
        try {
          await tester.pumpWidget(LetterApp(book: book));
          expect(find.byType(HomeScreen), findsOneWidget);
          expect(find.byType(CoverScreen), findsNothing);
          expect(find.byKey(const ValueKey('cover-enter')), findsNothing);
          expect(find.text('©nagano'), findsNothing);
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(_officialArtwork),
              tester.element(find.byType(HomeScreen)),
            ),
          );
          await tester.pumpAndSettle();

          final message = find.byKey(const ValueKey('home-unlock-message'));
          expect(find.textContaining('하루 한 장씩'), findsNothing);
          expect(
            find.text('${LetterConfig.senderName}가 보내는 ${book.totalDays}장의 편지'),
            findsNothing,
          );
          final messageWidget = tester.widget<Text>(message);
          expect(messageWidget.textAlign, TextAlign.left);
          expect(messageWidget.style!.fontSize, greaterThanOrEqualTo(24));
          expect(
            tester
                .widget<Text>(message)
                .data!
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim(),
            '3일차 편지가 열렸어요',
          );
          final progress = find.byKey(const ValueKey('home-progress'));
          expect(
            tester.widget<LinearProgressIndicator>(progress).value,
            closeTo(3 / book.totalDays, 0.000001),
          );
          for (final finder in [message, progress]) {
            final rect = tester.getRect(finder);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
          }

          // 홈 오른쪽 위의 표시 창만 검사한다. 확대된 원본은 의도적으로 크다.
          final artwork = find.byKey(const ValueKey('home-ode'));
          expect(artwork, findsOneWidget);
          final artworkRect = tester.getRect(artwork);
          expect(artworkRect.width, greaterThan(96));
          expect(artworkRect.height, greaterThan(0));
          expect(artworkRect.left, greaterThanOrEqualTo(0));
          expect(artworkRect.right, lessThanOrEqualTo(size.width));
          expect(artworkRect.top, greaterThanOrEqualTo(0));
          expect(artworkRect.bottom, lessThanOrEqualTo(size.height));
          expect(artworkRect.center.dx, greaterThan(size.width / 2));
          expect(
            tester.getRect(message).right,
            lessThanOrEqualTo(artworkRect.left),
          );
          expect(
            find.descendant(of: artwork, matching: find.byType(ClipOval)),
            findsNothing,
          );
          expect(
            find.descendant(of: artwork, matching: find.byType(ClipRect)),
            findsWidgets,
          );
          final images = find.descendant(
            of: artwork,
            matching: find.byType(Image),
            matchRoot: true,
          );
          expect(images, findsWidgets);
          for (final image in tester.widgetList<Image>(images)) {
            expect(image.image, isA<AssetImage>());
            expect((image.image as AssetImage).assetName, _officialArtwork);
            expect(image.color, isNull);
            expect(image.colorBlendMode, isNull);
            expect(image.fit, BoxFit.contain);
          }
          expect(
            find.descendant(
              of: artwork,
              matching: find.byType(ColorFiltered),
              matchRoot: true,
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);

          final open = find.byKey(const ValueKey('home-open-letter'));
          expect(open, findsOneWidget);
          await tester.ensureVisible(open);
          await tester.pumpAndSettle();
          final openRect = tester.getRect(open);
          expect(openRect.left, greaterThanOrEqualTo(0));
          expect(openRect.right, lessThanOrEqualTo(size.width));
          expect(openRect.top, greaterThanOrEqualTo(0));
          expect(openRect.bottom, lessThanOrEqualTo(size.height));
          await tester.tap(open);
          await tester.pumpAndSettle();
          final opened = tester
              .widget<LetterScreen>(find.byType(LetterScreen))
              .letter;
          expect(opened.day, inInclusiveRange(1, 3));
          expect(book.isRead(opened), isTrue);
          await _expectPlainLetter(tester, opened.day);
          await tester.tap(find.text('편지 모음'));
          await tester.pumpAndSettle();
          expect(find.byType(HomeScreen), findsOneWidget);

          final homeScroll = find
              .descendant(
                of: find.byType(HomeScreen),
                matching: find.byType(Scrollable),
              )
              .first;
          final locked = find.byKey(const ValueKey('letter-day-4'));
          await tester.scrollUntilVisible(locked, 180, scrollable: homeScroll);
          await tester.pumpAndSettle();
          final readBeforeLockedTap = book.readCount;
          await tester.tap(locked);
          await tester.pumpAndSettle();
          expect(find.byType(LetterScreen), findsNothing);
          expect(find.byType(HomeScreen), findsOneWidget);
          expect(book.isRead(book.letters[3]), isFalse);
          expect(book.readCount, readBeforeLockedTap);

          // 한 번에 생성되는 카드 수를 가정하지 않고 마지막 카드까지 찾아간다.
          final finalCard = find.byKey(const ValueKey('letter-day-66'));
          await tester.scrollUntilVisible(
            finalCard,
            300,
            scrollable: homeScroll,
            maxScrolls: 60,
          );
          await tester.pumpAndSettle();
          final finalRect = tester.getRect(finalCard);
          expect(finalRect.left, greaterThanOrEqualTo(0));
          expect(finalRect.right, lessThanOrEqualTo(size.width));
          expect(finalRect.top, greaterThanOrEqualTo(0));
          expect(finalRect.bottom, lessThanOrEqualTo(size.height));
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          book.dispose();
        }
      });
    }

    testWidgets('320px 글자 크기 1.5배에서도 왼쪽 문구와 오른쪽 원본 그림이 분리된다', (tester) async {
      tester.view
        ..devicePixelRatio = 1.0
        ..physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final book = await LetterBook.load(
        clock: () => DateTime(2026, 10, 12, 9),
        unlockAll: false,
      );
      try {
        await tester.pumpWidget(LetterApp(book: book));
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(_officialArtwork),
            tester.element(find.byType(HomeScreen)),
          ),
        );
        await tester.pumpAndSettle();

        final message = find.byKey(const ValueKey('home-unlock-message'));
        final artwork = find.byKey(const ValueKey('home-ode'));
        final messageWidget = tester.widget<Text>(message);
        expect(
          MediaQuery.textScalerOf(tester.element(message)).scale(10),
          closeTo(15, 0.000001),
        );
        expect(
          messageWidget.data!.replaceAll(RegExp(r'\s+'), ' ').trim(),
          '3일차 편지가 열렸어요',
        );
        expect(messageWidget.textAlign, TextAlign.left);
        expect(messageWidget.style!.fontSize, greaterThanOrEqualTo(24));
        expect(find.textContaining('하루 한 장씩'), findsNothing);
        expect(
          find.text('${LetterConfig.senderName}가 보내는 ${book.totalDays}장의 편지'),
          findsNothing,
        );
        final messageRect = tester.getRect(message);
        final artworkRect = tester.getRect(artwork);
        expect(messageRect.right, lessThanOrEqualTo(artworkRect.left));
        expect(artworkRect.width, greaterThan(96));
        for (final rect in [messageRect, artworkRect]) {
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(568));
        }
        expect(
          find.descendant(of: artwork, matching: find.byType(ClipOval)),
          findsNothing,
        );
        expect(
          find.descendant(of: artwork, matching: find.byType(ClipRect)),
          findsWidgets,
        );
        final images = find.descendant(
          of: artwork,
          matching: find.byType(Image),
        );
        expect(images, findsWidgets);
        for (final image in tester.widgetList<Image>(images)) {
          expect(image.image, isA<AssetImage>());
          expect((image.image as AssetImage).assetName, _officialArtwork);
          expect(image.color, isNull);
          expect(image.colorBlendMode, isNull);
          expect(image.fit, BoxFit.contain);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        book.dispose();
      }
    });

    for (final day in [1, 3]) {
      testWidgets('$day일차 본문은 그림 없이 날짜와 다음 편지 이동을 유지한다', (tester) async {
        tester.view
          ..devicePixelRatio = 1.0
          ..physicalSize = const Size(390, 840);
        addTearDown(tester.view.reset);
        final book = await LetterBook.load(
          clock: () => DateTime(2026, 10, 13, 9),
          unlockAll: false,
        );
        try {
          await tester.pumpWidget(
            LetterBookScope(
              book: book,
              child: MaterialApp(
                theme: buildTheme(),
                home: LetterScreen(letter: book.letters[day - 1]),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await _expectPlainLetter(tester, day);
          final next = find.widgetWithText(TextButton, '다음 편지 읽기  →');
          await tester.ensureVisible(next);
          await tester.pumpAndSettle();
          await tester.tap(next);
          await tester.pumpAndSettle();
          await _expectPlainLetter(tester, day + 1);
          expect(book.isRead(book.letters[day]), isTrue);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          book.dispose();
        }
      });
    }
  });
}

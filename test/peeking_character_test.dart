import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:jhjhjhjh/models/letter.dart';
import 'package:jhjhjhjh/theme.dart';
import 'package:jhjhjhjh/widgets/envelope_tile.dart';

const _tileKey = ValueKey('tested-letter-tile');

Future<void> _pumpTile(
  WidgetTester tester, {
  required int day,
  required LetterStatus status,
  Size size = const Size(84, 86),
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: size,
            child: EnvelopeTile(
              key: _tileKey,
              letter: Letter(day: day, body: '테스트 편지'),
              status: status,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  if (images.isNotEmpty) {
    await tester.runAsync(() async {
      for (final image in images) {
        await precacheImage(image.image, tester.element(find.byKey(_tileKey)));
      }
    });
  }
  await tester.pumpAndSettle();
}

Finder _character(int day) => find.byKey(ValueKey('tile-character-$day'));

Finder _characterImages(int day) => find.descendant(
  of: _character(day),
  matching: find.byType(Image),
  matchRoot: true,
);

Finder get _readCheck => find.byWidgetPredicate(
  (widget) =>
      widget is Icon &&
      const [
        Icons.check,
        Icons.check_rounded,
        Icons.check_circle,
        Icons.check_circle_rounded,
        Icons.check_circle_outline,
        Icons.check_circle_outline_rounded,
        Icons.done,
        Icons.done_rounded,
      ].contains(widget.icon),
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('날짜 칸의 빼꼼 캐릭터', () {
    const expectedCharacters = <int, String>{
      1: 'assets/chiikawa-face-official.png',
      2: 'assets/hachiware-face-official.png',
      3: 'assets/usagi-face-official.png',
      4: 'assets/ode-face-user.png',
      5: 'assets/goblin-face-official.png',
      6: 'assets/chiikawa-face-official.png',
    };
    for (final entry in expectedCharacters.entries) {
      testWidgets('${entry.key}일차는 다섯 종류 순서에 맞는 원본 얼굴을 표시한다', (tester) async {
        await _pumpTile(
          tester,
          day: entry.key,
          status: entry.key == 1 ? LetterStatus.today : LetterStatus.unread,
        );

        expect(_character(entry.key), findsOneWidget);
        final images = _characterImages(entry.key);
        expect(images, findsOneWidget);
        final image = tester.widget<Image>(images);
        expect(image.image, isA<AssetImage>());
        final asset = (image.image as AssetImage).assetName;
        expect(asset, entry.value);
        expect(image.color, isNull);
        expect(image.colorBlendMode, isNull);
        expect(find.byIcon(Icons.mail_outline), findsNothing);
        expect(find.byIcon(Icons.lock_outline), findsNothing);
        expect(_readCheck, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('잠긴 날짜에는 캐릭터 대신 잠금 아이콘과 잠김 안내가 나온다', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpTile(tester, day: 4, status: LetterStatus.locked);

        expect(find.byType(Image), findsNothing);
        expect(_character(4), findsNothing);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        expect(_readCheck, findsNothing);
        expect(find.bySemanticsLabel('4일차 편지, 10월 13일, 잠김'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('읽은 날짜도 얼굴을 유지하고 체크와 접근 가능한 탭 동작을 제공한다', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var tapCount = 0;
        await _pumpTile(
          tester,
          day: 2,
          status: LetterStatus.read,
          onTap: () => tapCount++,
        );

        expect(_character(2), findsOneWidget);
        expect(_characterImages(2), findsOneWidget);
        expect(_readCheck, findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsNothing);
        final accessibleTile = find.bySemanticsLabel('2일차 편지, 10월 11일, 읽음');
        expect(accessibleTile, findsOneWidget);
        final data = tester.getSemantics(accessibleTile).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        await tester.tap(find.byKey(_tileKey));
        await tester.pumpAndSettle();
        expect(tapCount, 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    for (final width in [60.0, 64.0, 91.0]) {
      for (final day in [3, 4, 5]) {
        testWidgets('$day일차 ${width.toInt()}px 카드에서 얼굴과 읽음 체크가 칸 안에 들어간다', (
          tester,
        ) async {
          await _pumpTile(
            tester,
            day: day,
            status: LetterStatus.read,
            size: Size(width, 86),
          );
          final image = tester.widget<Image>(_characterImages(day));
          expect(image.image, isA<AssetImage>());
          expect(
            (image.image as AssetImage).assetName,
            expectedCharacters[day],
          );
          final tileRect = tester.getRect(find.byKey(_tileKey));
          for (final finder in [_character(day), _readCheck]) {
            expect(finder, findsOneWidget);
            final rect = tester.getRect(finder);
            expect(rect.width, greaterThan(0));
            expect(rect.height, greaterThan(0));
            expect(rect.left, greaterThanOrEqualTo(tileRect.left));
            expect(rect.right, lessThanOrEqualTo(tileRect.right));
            expect(rect.top, greaterThanOrEqualTo(tileRect.top));
            expect(rect.bottom, lessThanOrEqualTo(tileRect.bottom));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

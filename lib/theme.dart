import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 흑백 사진집의 종이, 잉크, 얇은 인쇄선.
abstract final class Paper {
  static const Color base = Color(0xFFF4F4F4);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF292929);
  static const Color inkSoft = Color(0xFF747474);
  static const Color edge = Color(0xFFE4E4E4);

  /// 포인트색. 배경이 흰색이라 포인트도 검정으로 통일합니다.
  static const Color seal = ink;

  /// 강조 블록의 옅은 바탕.
  static const Color sealSoft = Color(0xFFEDEDED);
  static const Color locked = Color(0xFF92928D);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Paper.base,
    colorScheme: const ColorScheme.light(
      primary: Paper.ink,
      onPrimary: Paper.card,
      secondary: Paper.inkSoft,
      surface: Paper.base,
      onSurface: Paper.ink,
      outline: Paper.edge,
    ),
  );

  return base.copyWith(
    dividerTheme: const DividerThemeData(
      color: Paper.edge,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Paper.ink,
        foregroundColor: Paper.card,
        minimumSize: const Size(48, 54),
        shape: const RoundedRectangleBorder(),
      ),
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme(
      base.textTheme,
    ).apply(bodyColor: Paper.ink, displayColor: Paper.ink),
  );
}

/// 커버의 큰 헤드라인용. 굵고 납작하게.
TextStyle displayStyle({
  required double size,
  FontWeight weight = FontWeight.w500,
}) => GoogleFonts.notoSansKr(
  fontSize: size,
  height: 1.2,
  fontWeight: weight,
  letterSpacing: -1.2,
  color: Paper.ink,
);

/// 편지 본문은 장식 없이 또렷한 고딕으로 읽습니다.
TextStyle letterBodyStyle(BuildContext context) => GoogleFonts.notoSansKr(
  fontSize: 17,
  height: 2.0,
  letterSpacing: 0,
  color: Paper.ink,
);

TextStyle letterTitleStyle(BuildContext context) => GoogleFonts.notoSansKr(
  fontSize: 24,
  height: 1.35,
  fontWeight: FontWeight.w500,
  letterSpacing: -0.6,
  color: Paper.ink,
);

TextStyle editorialStyle({
  required double size,
  FontWeight weight = FontWeight.w400,
  Color color = Paper.ink,
}) => GoogleFonts.notoSansKr(
  fontSize: size,
  height: 1.2,
  fontWeight: weight,
  letterSpacing: size >= 24 ? -1.2 : 0,
  color: color,
);

TextStyle labelStyle({Color color = Paper.inkSoft, double size = 10}) =>
    GoogleFonts.notoSansKr(
      fontSize: size,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.8,
      height: 1.5,
      color: color,
    );

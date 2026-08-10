import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 흰 배경 · 검정 포인트.
abstract final class Paper {
  static const Color base = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF000000);
  static const Color inkSoft = Color(0xFF8A8A8A);
  static const Color edge = Color(0xFFE3E3E3);

  /// 포인트색. 배경이 흰색이라 포인트도 검정으로 통일합니다.
  static const Color seal = Color(0xFF000000);

  /// 강조 블록의 옅은 바탕.
  static const Color sealSoft = Color(0xFFF2F2F2);
  static const Color locked = Color(0xFFC9C9C9);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Paper.base,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Paper.ink,
      surface: Paper.base,
      brightness: Brightness.light,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme).apply(
      bodyColor: Paper.ink,
      displayColor: Paper.ink,
    ),
  );
}

/// 커버의 큰 헤드라인용. 굵고 납작하게.
TextStyle displayStyle({required double size, FontWeight weight = FontWeight.w900}) =>
    GoogleFonts.notoSansKr(
      fontSize: size,
      height: 1.05,
      fontWeight: weight,
      letterSpacing: -1.5,
      color: Paper.ink,
    );

/// 편지 본문. 읽는 맛을 위해 여기만 명조를 씁니다.
TextStyle letterBodyStyle(BuildContext context) => GoogleFonts.gowunBatang(
      fontSize: 17,
      height: 2.0,
      letterSpacing: 0.2,
      color: Paper.ink,
    );

TextStyle letterTitleStyle(BuildContext context) => GoogleFonts.notoSansKr(
      fontSize: 24,
      height: 1.35,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: Paper.ink,
    );

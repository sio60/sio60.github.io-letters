import 'package:flutter/material.dart';

import 'home_screen.dart';

/// 이전 표지 진입점도 별도 클릭 없이 편지 달력을 엽니다.
class CoverScreen extends StatelessWidget {
  const CoverScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

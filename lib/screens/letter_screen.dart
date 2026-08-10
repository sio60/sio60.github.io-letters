import 'package:flutter/material.dart';

import '../config.dart';
import '../models/letter.dart';
import '../state/letter_book.dart';
import '../theme.dart';
import '../util/korean_text.dart';

/// 편지 한 장을 읽는 화면.
class LetterScreen extends StatefulWidget {
  const LetterScreen({super.key, required this.letter});

  final Letter letter;

  /// 봉투가 펼쳐지듯 열리는 전환.
  static Route<void> route(Letter letter) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 480),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => LetterScreen(letter: letter),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 뜬 직후 읽음으로 표시합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) LetterBookScope.of(context).markRead(widget.letter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(day: letter.day, total: LetterConfig.totalDays),
                Expanded(
                  // 편지가 짧아도 종이 한 장으로 보이도록 최소 높이를 줍니다.
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(13, 8, 13, 28),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
                        child: _Paper(letter: letter),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.day, required this.total});

  final int day;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Paper.inkSoft),
            tooltip: '목록으로',
          ),
          const Spacer(),
          Text(
            '$day / $total',
            style: const TextStyle(fontSize: 12, letterSpacing: 2, color: Paper.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _Paper extends StatelessWidget {
  const _Paper({required this.letter});

  final Letter letter;

  @override
  Widget build(BuildContext context) {
    final date = letter.unlockDate;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 36),
      decoration: BoxDecoration(
        color: Paper.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Paper.edge),
        boxShadow: [
          BoxShadow(
            color: Paper.ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WaxSeal(),
          const SizedBox(height: 24),
          Text(
            '${date.year}년 ${date.month}월 ${date.day}일 · ${letter.day}일차',
            style: const TextStyle(fontSize: 12, letterSpacing: 0.5, color: Paper.inkSoft),
          ),
          const SizedBox(height: 18),
          SelectableText(
            keepWordsWhole(
              letter.body.isEmpty ? '(아직 비어 있는 편지)' : letter.body,
            ),
            style: letterBodyStyle(context),
          ),
          const SizedBox(height: 36),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              LetterConfig.senderName,
              style: letterBodyStyle(context).copyWith(fontSize: 15, color: Paper.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// 편지 머리에 찍힌 밀랍 봉인.
class _WaxSeal extends StatelessWidget {
  const _WaxSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Paper.seal,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Paper.seal.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: const Icon(Icons.favorite_rounded, size: 16, color: Paper.sealSoft),
    );
  }
}

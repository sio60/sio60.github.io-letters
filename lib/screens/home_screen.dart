import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../models/letter.dart';
import '../state/letter_book.dart';
import '../theme.dart';
import '../widgets/envelope_tile.dart';
import 'letter_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final book = LetterBookScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                SliverToBoxAdapter(child: _StatusCard(book: book)),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                const SliverToBoxAdapter(child: _GridLabel()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 76,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.86,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final letter = book.letters[index];
                        return EnvelopeTile(
                          letter: letter,
                          status: book.statusOf(letter),
                          onTap: () => _open(context, book, letter),
                        );
                      },
                      childCount: book.totalDays,
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

  void _open(BuildContext context, LetterBook book, Letter letter) {
    if (!book.isUnlocked(letter)) {
      final days = letter.unlockDate.difference(DateTime.now()).inHours ~/ 24 + 1;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            width: 260,
            backgroundColor: Paper.ink,
            content: Text(
              '${letter.day}일차 편지는 아직이야. $days일 남았어.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Paper.base),
            ),
          ),
        );
      return;
    }
    Navigator.of(context).push(LetterScreen.route(letter));
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Paper.ink),
              tooltip: '표지로',
            ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LetterConfig.recipientName,
                  style: const TextStyle(fontSize: 12, letterSpacing: 1, color: Paper.inkSoft),
                ),
                const SizedBox(height: 8),
                Text(LetterConfig.appTitle, style: displayStyle(size: 34)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 오늘의 상태를 알려주는 큰 카드. 화면에서 제일 중요한 부분입니다.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.book});

  final LetterBook book;

  @override
  Widget build(BuildContext context) {
    if (!book.hasStarted) {
      return _Card(
        title: '아직 시작 전이야',
        subtitle: '${book.daysUntilStart}일 뒤에 첫 번째 편지가 열려.',
      );
    }

    // 밀린 편지가 있으면 오늘 것보다 먼저 안내합니다.
    final next = book.oldestUnread;
    if (next != null) {
      final backlog = book.unreadCount - 1;
      return _Card(
        title: book.isTodays(next) ? '오늘의 편지가 도착했어' : '${next.day}일차 편지를 아직 안 읽었어',
        subtitle: backlog > 0
            ? '${next.day}일차 · 뒤이어 읽을 편지가 $backlog장 더 있어.'
            : '${next.day}일차 · ${book.totalDays}일 중',
        accent: true,
        action: ('열어보기', () => Navigator.of(context).push(LetterScreen.route(next))),
      );
    }

    if (book.isComplete) {
      return _Card(title: '편지는 여기까지야', subtitle: LetterConfig.finaleMessage);
    }

    return _Card(
      title: '오늘 편지는 다 읽었어',
      subtitle: '다음 편지까지',
      countdown: true,
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    this.accent = false,
    this.countdown = false,
    this.action,
  });

  final String title;
  final String subtitle;
  final bool accent;
  final bool countdown;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    final book = LetterBookScope.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Paper.card,
        borderRadius: BorderRadius.circular(18),
        // 강조할 때는 색을 채우는 대신 테두리를 굵게 — 흑백 톤을 유지합니다.
        border: Border.all(
          color: accent ? Paper.ink : Paper.edge,
          width: accent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: letterTitleStyle(context).copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 14, height: 1.6, color: Paper.inkSoft)),
          if (countdown) ...[
            const SizedBox(height: 6),
            const _Countdown(),
          ],
          if (action != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: action!.$2,
              style: FilledButton.styleFrom(
                backgroundColor: Paper.ink,
                foregroundColor: Paper.base,
                minimumSize: const Size(double.infinity, 50),
                shape: const StadiumBorder(),
              ),
              child: Text(
                action!.$1,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _Progress(read: book.unlockedCount, total: book.totalDays),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.read, required this.total});

  final int read;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : read / total,
              minHeight: 5,
              backgroundColor: Paper.edge,
              valueColor: const AlwaysStoppedAnimation(Paper.seal),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$read / $total',
          style: const TextStyle(fontSize: 12, color: Paper.inkSoft, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

/// 다음 편지가 열릴 때까지 남은 시간을 1초마다 갱신합니다.
class _Countdown extends StatefulWidget {
  const _Countdown();

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = LetterBookScope.of(context).timeUntilNext;
    if (remaining == null) return const SizedBox.shrink();

    String pad(int n) => n.toString().padLeft(2, '0');
    final text = '${pad(remaining.inHours)}:${pad(remaining.inMinutes % 60)}:'
        '${pad(remaining.inSeconds % 60)}';

    return Text(
      text,
      style: letterTitleStyle(context).copyWith(
        fontSize: 30,
        color: Paper.seal,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _GridLabel extends StatelessWidget {
  const _GridLabel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        '전체 편지',
        style: TextStyle(fontSize: 12, letterSpacing: 0.5, color: Paper.inkSoft),
      ),
    );
  }
}

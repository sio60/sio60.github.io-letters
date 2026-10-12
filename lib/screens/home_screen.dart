import 'package:flutter/material.dart';

import '../config.dart';
import '../models/letter.dart';
import '../state/letter_book.dart';
import '../theme.dart';
import '../widgets/envelope_tile.dart';
import '../widgets/stationery_characters.dart';
import 'letter_screen.dart';

const _sage = Color(0xFF52715B);

/// 첫 화면에서 날짜별 공개 상태를 바로 확인하는 편지 달력.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final book = LetterBookScope.of(context);
    final latest = book.hasStarted
        ? book.letters[book.unlockedCount - 1]
        : null;
    final toRead = book.oldestUnread ?? latest;

    return Scaffold(
      backgroundColor: Paper.card,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Paper.card,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          LetterConfig.appTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final inset = constraints.maxWidth >= 600 ? 40.0 : 20.0;
                final columns = constraints.maxWidth >= 600
                    ? 7
                    : constraints.maxWidth >= 360
                    ? 5
                    : 4;
                final textScale =
                    MediaQuery.textScalerOf(context).scale(12) / 12;
                return CustomScrollView(
                  key: const ValueKey('home-scroll'),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(inset, 20, inset, 0),
                      sliver: SliverList.list(
                        children: [
                          _ArrivalHeader(book: book),
                          const SizedBox(height: 26),
                          _OpeningProgress(book: book),
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              const Text(
                                '전체 편지',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '읽은 편지 ${book.readCount}장',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Paper.inkSoft,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(inset, 0, inset, 28),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 8,
                          mainAxisExtent: 86 * textScale.clamp(1.0, 1.5),
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final letter = book.letters[index];
                          return EnvelopeTile(
                            key: ValueKey('letter-day-${letter.day}'),
                            letter: letter,
                            status: book.statusOf(letter),
                            onTap: () => _open(context, book, letter),
                          );
                        }, childCount: book.totalDays),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Center(
                          child: Text(
                            '${LetterConfig.senderName}가, ${LetterConfig.recipientName}에게',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Paper.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: _ReadAction(
        book: book,
        letter: toRead,
        onTap: toRead == null ? null : () => _open(context, book, toRead),
      ),
    );
  }

  void _open(BuildContext context, LetterBook book, Letter letter) {
    if (!book.isUnlocked(letter)) {
      final date = letter.unlockDate;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Paper.ink,
            content: Text(
              '${letter.day}일차 편지는 ${date.month}월 ${date.day}일에 열려요.',
            ),
          ),
        );
      return;
    }
    Navigator.of(context).push(LetterScreen.route(letter));
  }
}

class _ArrivalHeader extends StatelessWidget {
  const _ArrivalHeader({required this.book});
  final LetterBook book;

  @override
  Widget build(BuildContext context) {
    final message = !book.hasStarted
        ? '첫 편지를\n기다리고 있어요'
        : book.isComplete
        ? '모든 편지가\n열렸어요'
        : '${book.unlockedCount}일차 편지가\n열렸어요';
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                message,
                key: const ValueKey('home-unlock-message'),
                textAlign: TextAlign.left,
                style: displayStyle(
                  size: 26,
                  weight: FontWeight.w700,
                ).copyWith(height: 1.4, letterSpacing: -0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OdeArtwork(
            key: const ValueKey('home-ode'),
            size: constraints.maxWidth >= 340 ? 132 : 112,
          ),
        ],
      ),
    );
  }
}

class _OpeningProgress extends StatelessWidget {
  const _OpeningProgress({required this.book});
  final LetterBook book;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const Text(
            '열린 편지',
            style: TextStyle(fontSize: 12, color: Paper.inkSoft),
          ),
          const Spacer(),
          Text(
            '${book.unlockedCount} / ${book.totalDays}',
            style: const TextStyle(
              fontSize: 12,
              color: _sage,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      LinearProgressIndicator(
        key: const ValueKey('home-progress'),
        value: book.totalDays == 0 ? 0 : book.unlockedCount / book.totalDays,
        minHeight: 10,
        borderRadius: BorderRadius.circular(20),
        backgroundColor: const Color(0xFFF1F3F1),
        color: _sage,
        semanticsLabel: '전체 ${book.totalDays}장 중 ${book.unlockedCount}장 열림',
      ),
      const SizedBox(height: 9),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '1일차',
            style: TextStyle(fontSize: 10, color: Paper.inkSoft),
          ),
          Text(
            '${book.totalDays}일차',
            style: const TextStyle(fontSize: 10, color: Paper.inkSoft),
          ),
        ],
      ),
    ],
  );
}

class _ReadAction extends StatelessWidget {
  const _ReadAction({
    required this.book,
    required this.letter,
    required this.onTap,
  });
  final LetterBook book;
  final Letter? letter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final next = book.isComplete ? null : book.letters[book.unlockedCount];
    final helper = next == null
        ? '${book.totalDays}장의 편지가 모두 도착했어요.'
        : '${next.unlockDate.month}월 ${next.unlockDate.day}일에 ${next.day}일차 편지가 열려요.';
    final label = letter == null
        ? '첫 편지를 기다리는 중'
        : book.isRead(letter!)
        ? '${letter!.day}일차 편지 다시 읽기'
        : '${letter!.day}일차 편지 읽기';
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Paper.card,
        border: Border(top: BorderSide(color: Paper.edge, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('home-open-letter'),
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: Paper.ink,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: Theme.of(
                        context,
                      ).textTheme.labelLarge!.copyWith(fontSize: 13),
                    ),
                    child: Text(label, textAlign: TextAlign.center),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                helper,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: Paper.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

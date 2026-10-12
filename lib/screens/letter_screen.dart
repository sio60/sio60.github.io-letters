import 'package:flutter/material.dart';

import '../config.dart';
import '../models/letter.dart';
import '../state/letter_book.dart';
import '../theme.dart';
import '../util/korean_text.dart';

/// 밝은 편지지 위에서 원문을 읽는 화면.
class LetterScreen extends StatefulWidget {
  const LetterScreen({super.key, required this.letter});

  final Letter letter;

  static Route<void> route(Letter letter) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) =>
        LetterScreen(letter: letter),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) LetterBookScope.of(context).markRead(widget.letter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter;
    final book = LetterBookScope.of(context);
    final next = letter.day < book.totalDays ? book.letters[letter.day] : null;
    final canReadNext = next != null && book.isUnlocked(next);
    final date = letter.unlockDate;
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final entryDate = letter.entryDate;
    final entryDateLabel =
        '${entryDate.year}.${entryDate.month.toString().padLeft(2, '0')}.${entryDate.day.toString().padLeft(2, '0')}';
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontSize: 17,
      height: 2.05,
      letterSpacing: 0,
      color: Paper.ink,
    );

    return Scaffold(
      backgroundColor: Paper.card,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 24, 8),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text(
                          '편지 모음',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${letter.day}일차',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Paper.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, viewport) => SingleChildScrollView(
                      key: ValueKey('letter-scroll-${letter.day}'),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: viewport.maxHeight,
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                36,
                                28,
                                40,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 520,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '공개일 $dateLabel',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Paper.inkSoft,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Text(
                                        '${LetterConfig.recipientName}에게,',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                          color: Paper.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      SelectableText(
                                        keepWordsWhole(
                                          letter.body.isEmpty
                                              ? '(아직 비어 있는 편지)'
                                              : letter.body,
                                        ),
                                        style: bodyStyle,
                                      ),
                                      const SizedBox(height: 36),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          LetterConfig.senderName,
                                          style: bodyStyle.copyWith(
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          entryDateLabel,
                                          key: const ValueKey(
                                            'letter-entry-date',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Paper.inkSoft,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 44),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      if (canReadNext)
                                        TextButton(
                                          onPressed: () => Navigator.of(context)
                                              .pushReplacement(
                                                LetterScreen.route(next),
                                              ),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: const Text('다음 편지 읽기  →'),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Text(
                                            next == null
                                                ? LetterConfig.finaleMessage
                                                : '${next.unlockDate.month}월 ${next.unlockDate.day}일에 다음 편지가 열려.',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Paper.inkSoft,
                                              height: 1.6,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 28),
                                      Center(
                                        child: Text(
                                          '${letter.day} / ${book.totalDays}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Paper.inkSoft,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

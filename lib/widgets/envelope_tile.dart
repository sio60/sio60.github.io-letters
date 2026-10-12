import 'package:flutter/material.dart';

import '../models/letter.dart';
import '../theme.dart';
import 'stationery_characters.dart';

/// 출석표처럼 하루씩 확인하는 작은 편지 칸.
class EnvelopeTile extends StatelessWidget {
  const EnvelopeTile({
    super.key,
    required this.letter,
    required this.status,
    required this.onTap,
  });

  final Letter letter;
  final LetterStatus status;
  final VoidCallback onTap;

  bool get _locked => status == LetterStatus.locked;

  String get _stateLabel => switch (status) {
    LetterStatus.locked => '잠김',
    LetterStatus.today => '오늘',
    LetterStatus.read => '읽음',
    LetterStatus.unread => '안 읽음',
  };

  @override
  Widget build(BuildContext context) {
    final isToday = status == LetterStatus.today;
    final read = status == LetterStatus.read;
    const radius = BorderRadius.all(Radius.circular(12));
    final foreground = _locked ? Paper.inkSoft : const Color(0xFF5D674E);
    final background = isToday
        ? const Color(0xFFFFF9E8)
        : _locked
        ? const Color(0xFFFAFAF8)
        : const Color(0xFFF1F6F1);
    final date = letter.unlockDate;
    final dateLabel =
        '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return Semantics(
      button: true,
      label: '${letter.day}일차 편지, ${date.month}월 ${date.day}일, $_stateLabel',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isToday
                ? const Color(0xFF7F855B)
                : _locked
                ? const Color(0xFFEFEFEC)
                : const Color(0xFFE6EBE4),
            width: isToday ? 1.2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 7, 5, 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${letter.day}일차',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                      if (read) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.check, size: 11, color: foreground),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _locked
                    ? Center(
                        child: Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: foreground,
                        ),
                      )
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: PeekCharacterArtwork(
                          key: ValueKey('tile-character-${letter.day}'),
                          day: letter.day,
                        ),
                      ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(5, 4, 5, 6),
                decoration: BoxDecoration(
                  color: background,
                  border: _locked
                      ? null
                      : const Border(top: BorderSide(color: Color(0xFFDDE3D8))),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      color: foreground,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

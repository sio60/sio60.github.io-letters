import 'package:flutter/material.dart';

import '../models/letter.dart';
import '../theme.dart';

/// 격자에 놓이는 편지 한 장. 상태에 따라 봉투 모양과 색이 달라집니다.
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

  @override
  Widget build(BuildContext context) {
    final isToday = status == LetterStatus.today;

    return Semantics(
      button: true,
      label: _locked ? '${letter.day}일차 편지, 아직 잠김' : '${letter.day}일차 편지',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (!_locked)
              BoxShadow(
                color: (isToday ? Paper.seal : Paper.ink).withValues(alpha: isToday ? 0.24 : 0.08),
                blurRadius: isToday ? 16 : 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Material(
          color: _locked ? const Color(0xFFF5F5F5) : Paper.card,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _EnvelopePainter(status: status),
              child: Center(
                child: _locked
                    ? Icon(Icons.lock_outline_rounded, size: 16, color: Paper.locked)
                    : _DayNumber(day: letter.day, status: status),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayNumber extends StatelessWidget {
  const _DayNumber({required this.day, required this.status});

  final int day;
  final LetterStatus status;

  @override
  Widget build(BuildContext context) {
    final read = status == LetterStatus.read;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$day',
          style: TextStyle(
            fontSize: 17,
            fontWeight: read ? FontWeight.w400 : FontWeight.w700,
            color: read ? Paper.inkSoft : Paper.ink,
          ),
        ),
        const SizedBox(height: 3),
        // 안 읽은 편지에는 밀랍 봉인을 찍어 눈에 띄게 합니다.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: read ? 0 : 1,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Paper.seal, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

/// 봉투 테두리와 뚜껑(플랩)을 그립니다. 읽은 편지는 뚜껑이 열린 모양.
class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter({required this.status});

  final LetterStatus status;

  @override
  void paint(Canvas canvas, Size size) {
    final locked = status == LetterStatus.locked;
    final isToday = status == LetterStatus.today;

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isToday ? 1.6 : 1.0
      ..color = locked
          ? Paper.locked.withValues(alpha: 0.6)
          : isToday
              ? Paper.seal
              : Paper.edge;

    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.8), const Radius.circular(10)),
      border,
    );

    // 뚜껑: 닫혀 있으면 아래로 향한 V, 열려 있으면 위로 젖혀진 얕은 V.
    final flap = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = locked ? Paper.locked.withValues(alpha: 0.5) : Paper.edge;

    final opened = status == LetterStatus.read;
    final apexY = opened ? size.height * 0.10 : size.height * 0.42;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.12, size.height * 0.26)
        ..lineTo(size.width * 0.5, apexY)
        ..lineTo(size.width * 0.88, size.height * 0.26),
      flap,
    );
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) => old.status != status;
}

import 'package:flutter/material.dart';

import '../theme.dart';

/// 캐릭터가 말하는 말풍선. 흰 바탕에 검정 테두리, 꼬리는 오른쪽 아래를 향합니다.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.child});

  static const double _tailHeight = 12;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _BubblePainter(tailHeight: _tailHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 11 + _tailHeight),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.tailHeight});

  final double tailHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyHeight = size.height - tailHeight;
    if (bodyHeight <= 0) return;

    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, bodyHeight - 1),
          const Radius.circular(16),
        ),
      );

    // 꼬리는 오른쪽 아래 — 캐릭터 머리 쪽을 가리킵니다.
    final tail = Path()
      ..moveTo(size.width * 0.60, bodyHeight - 6)
      ..lineTo(size.width * 0.70, size.height - 1)
      ..lineTo(size.width * 0.78, bodyHeight - 6)
      ..close();

    final shape = Path.combine(PathOperation.union, body, tail);

    canvas.drawPath(shape, Paint()..color = Paper.base);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = Paper.ink,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.tailHeight != tailHeight;
}

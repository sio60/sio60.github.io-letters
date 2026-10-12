import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

/// 미리보기 스위치가 켜져 있을 때 화면 맨 위에 붙는 경고 띠.
///
/// 이게 보이면 날짜와 상관없이 편지가 전부 열려 있는 상태입니다.
/// 재희에게 주기 전에 [LetterConfig.unlockAllForPreview] 를 false 로 바꿔야 합니다.
class PreviewBanner extends StatelessWidget {
  const PreviewBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!LetterConfig.unlockAllForPreview) return child;

    // 띠가 화면을 덮으면 뒤로가기 버튼이 가려집니다. 위로 밀어내고,
    // 상태바 여백은 띠가 대신 먹었으니 아래쪽에서 중복으로 넣지 않게 걷어냅니다.
    return Column(
      children: [
        Material(
          color: Paper.sealSoft,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 6),
              child: Text(
                '미리보기 · ${LetterConfig.totalDays}장의 편지를 모두 볼 수 있어요',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Paper.inkSoft,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

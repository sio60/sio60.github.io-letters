import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';
import '../widgets/speech_bubble.dart';
import 'home_screen.dart';

/// 앱을 열면 제일 먼저 보이는 표지.
///
/// 오른쪽 위에 1주년 문구, 오른쪽 아래에 유나 캐릭터와 말풍선.
class CoverScreen extends StatelessWidget {
  const CoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paper.base,
      body: SafeArea(
        child: Center(
          // 넓은 화면에서 위아래로 늘어지지 않도록 세로도 묶어 둡니다.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 780),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 캐릭터가 화면을 잡아먹지 않도록 폭을 묶어둡니다.
                final characterWidth =
                    (constraints.maxWidth * 0.88).clamp(230.0, 350.0);

                // Stack 으로 절대 배치하면 낮은 화면에서 문구와 캐릭터가 겹칩니다.
                // 남는 높이를 캐릭터에 주고, 모자라면 캐릭터만 줄어들게 합니다.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 40, 26, 0),
                      child: _Headline(),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomRight,
                          child: _Character(width: characterWidth),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          LetterConfig.coverLabel,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 3.5,
            fontWeight: FontWeight.w700,
            color: Paper.inkSoft,
          ),
        ),
        const SizedBox(height: 18),
        Text(LetterConfig.coverLead, style: displayStyle(size: 32)),
        Text(LetterConfig.coverHeadline, style: displayStyle(size: 58)),
        const SizedBox(height: 28),
        const _EnterButton(),
      ],
    );
  }
}

class _EnterButton extends StatelessWidget {
  const _EnterButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: Paper.ink,
        foregroundColor: Paper.base,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LetterConfig.coverAction,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_rounded, size: 17),
        ],
      ),
    );
  }
}

class _Character extends StatelessWidget {
  const _Character({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 말풍선 꼬리가 캐릭터 머리 왼쪽을 가리키도록 폭에 비례해 띄웁니다.
        Padding(
          padding: EdgeInsets.only(left: width * 0.24),
          child: const SpeechBubble(
            child: Icon(Icons.favorite_rounded, size: 22, color: Paper.ink),
          ),
        ),
        const SizedBox(height: 2),
        Image.asset(
          'assets/yuna.png',
          width: width,
          filterQuality: FilterQuality.high,
        ),
      ],
    );
  }
}

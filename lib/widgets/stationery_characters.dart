import 'package:flutter/material.dart';

/// 날짜 칸의 아래쪽 선 너머로 고개를 내미는 캐릭터 원본.
/// 이미지 파일을 가공하지 않고 얼굴 아래쪽만 표시 창으로 가립니다.
class PeekCharacterArtwork extends StatelessWidget {
  const PeekCharacterArtwork({super.key, required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final (asset, sourceSize, window) = switch ((day - 1) % 5) {
      0 => (
        'assets/chiikawa-face-official.png',
        const Size(400, 400),
        const Rect.fromLTWH(42, 68, 316, 204),
      ),
      1 => (
        'assets/hachiware-face-official.png',
        const Size(400, 400),
        const Rect.fromLTWH(47, 64, 309, 212),
      ),
      2 => (
        'assets/usagi-face-official.png',
        const Size(400, 400),
        const Rect.fromLTWH(45, 24, 310, 264),
      ),
      3 => (
        'assets/ode-face-user.png',
        const Size(1463, 1434),
        const Rect.fromLTWH(145, 0, 1200, 880),
      ),
      _ => (
        'assets/goblin-face-official.png',
        const Size(400, 400),
        const Rect.fromLTWH(23, 64, 353, 212),
      ),
    };

    return ExcludeSemantics(
      child: SizedBox(
        width: 50,
        height: 43,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: window.width,
            height: window.height,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: sourceSize.width,
                maxWidth: sourceSize.width,
                minHeight: sourceSize.height,
                maxHeight: sourceSize.height,
                child: Transform.translate(
                  offset: Offset(-window.left, -window.top),
                  child: Image.asset(
                    asset,
                    width: sourceSize.width,
                    height: sourceSize.height,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 공식 원본 중 오데와 고블린이 함께 있는 영역을 그대로 표시합니다.
/// 출처: assets/chiikawa-artwork-source.txt. 재생성·색상 변경 없음.
class OdeArtwork extends StatelessWidget {
  const OdeArtwork({super.key, this.size = 132});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 214 / 156,
          child: FittedBox(
            fit: BoxFit.contain,
            // 흰 배경 안쪽만 표시해 원본에 인쇄된 원형 테두리를 제외합니다.
            // 캐릭터와 들고 있는 고블린들의 픽셀은 그대로 유지합니다.
            child: SizedBox(
              width: 156,
              height: 214,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: 1500,
                  maxWidth: 1500,
                  minHeight: 1500,
                  maxHeight: 1500,
                  child: Transform.translate(
                    offset: const Offset(-382, -588),
                    child: Image.asset(
                      'assets/chiikawa-official-artwork.webp',
                      width: 1500,
                      height: 1500,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

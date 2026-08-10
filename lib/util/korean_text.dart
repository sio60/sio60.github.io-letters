/// 줄바꿈을 막는 보이지 않는 문자 (word joiner).
const String _wordJoiner = '⁠';

/// 한글은 글자 사이 어디서나 줄이 바뀌어서 "마음에" 가 "마음 / 에" 로 갈라집니다.
///
/// 단어 안쪽에 word joiner 를 끼워 넣어 띄어쓰기에서만 줄이 바뀌게 만듭니다.
/// (CSS 의 word-break: keep-all 과 같은 효과)
String keepWordsWhole(String text) => text
    .split('\n')
    .map((line) => line.split(' ').map(_glue).join(' '))
    .join('\n');

String _glue(String word) {
  final runes = word.runes.toList();
  if (runes.length < 2) return word;
  return runes.map(String.fromCharCode).join(_wordJoiner);
}

import '../models/letter.dart';
import 'codec.dart';
import 'letters_data.dart';

/// 번들에 내장된 편지들을 복호화해서 읽어옵니다.
List<Letter> loadLetters() => [
  for (var i = 0; i < kEncodedLetters.length; i++)
    Letter(day: i + 1, body: deobfuscate(kEncodedLetters[i]).trim()),
];

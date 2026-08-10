import 'dart:convert';
import 'dart:typed_data';

/// 편지 본문을 앱 번들 안에서 평문으로 노출시키지 않기 위한 가벼운 난독화.
///
/// 암호화가 아닙니다 — 작정하고 뜯어보면 풀 수 있습니다.
/// 목적은 "빌드 파일을 우연히 열어봤을 때 편지가 그대로 읽히는 것"을 막는 것뿐입니다.
const String _key = 'sixty-five-days-of-letters';

String obfuscate(String plain) => base64Encode(_xor(utf8.encode(plain)));

String deobfuscate(String encoded) => utf8.decode(_xor(base64Decode(encoded)));

Uint8List _xor(List<int> bytes) {
  final key = utf8.encode(_key);
  final out = Uint8List(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    out[i] = bytes[i] ^ key[i % key.length];
  }
  return out;
}

// letters/letters.txt 원고를 읽어서 lib/data/letters_data.dart 를 생성합니다.
//
// 실행:  dart run tool/build_letters.dart
import 'dart:io';

import 'package:jhjhjhjh/data/codec.dart';

const String _sourcePath = 'letters/letters.txt';
const String _outputPath = 'lib/data/letters_data.dart';

/// "== 12 ==" 형태의 편지 구분선.
final RegExp _headerPattern = RegExp(r'^\s*={2,}\s*(\d+)\s*={2,}\s*$');

void main() {
  final source = File(_sourcePath);
  if (!source.existsSync()) {
    stderr.writeln('원고 파일을 찾을 수 없습니다: $_sourcePath');
    exitCode = 1;
    return;
  }

  final parsed = _parse(source.readAsLinesSync());
  if (parsed.isEmpty) {
    stderr.writeln('$_sourcePath 에서 편지를 하나도 찾지 못했습니다. "== 1 ==" 형식의 구분선이 필요합니다.');
    exitCode = 1;
    return;
  }

  final days = parsed.keys.toList()..sort();
  final missing = [
    for (var d = 1; d <= days.last; d++)
      if (!parsed.containsKey(d)) d,
  ];
  if (missing.isNotEmpty) {
    stderr.writeln('중간에 빠진 일차가 있습니다: ${missing.join(', ')}');
    exitCode = 1;
    return;
  }

  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE — 직접 수정하지 마세요.')
    ..writeln('// letters/letters.txt 를 고친 뒤 아래 명령을 실행하면 다시 생성됩니다.')
    ..writeln('//   dart run tool/build_letters.dart')
    ..writeln()
    ..writeln('const List<String> kEncodedLetters = <String>[');

  for (final day in days) {
    buffer.writeln('  // $day일차 — ${_summarize(parsed[day]!)}');
    buffer.writeln("  '${obfuscate(parsed[day]!)}',");
  }
  buffer.writeln('];');

  File(_outputPath).writeAsStringSync(buffer.toString());

  final unwritten = days.where((d) => parsed[d]!.startsWith('글감:')).toList();
  stdout.writeln('편지 ${days.length}장을 $_outputPath 에 생성했습니다.');
  if (unwritten.isNotEmpty) {
    stdout.writeln('아직 글감만 있는 일차 (${unwritten.length}장): ${unwritten.join(', ')}');
  }
}

/// 첫 구분선 앞의 내용은 전부 주석으로 보고 버립니다.
/// 구분선 다음부터 다음 구분선 전까지가 통째로 본문입니다.
Map<int, String> _parse(List<String> lines) {
  final result = <int, String>{};
  int? currentDay;
  var chunk = <String>[];

  void flush() {
    if (currentDay == null) return;
    result[currentDay] = chunk.join('\n').trim();
  }

  for (final line in lines) {
    final match = _headerPattern.firstMatch(line);
    if (match != null) {
      flush();
      currentDay = int.parse(match.group(1)!);
      chunk = <String>[];
      continue;
    }
    if (currentDay != null) chunk.add(line);
  }
  flush();

  return result;
}

String _summarize(String body) {
  final oneLine = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (oneLine.isEmpty) return '(비어 있음)';
  return oneLine.length <= 24 ? oneLine : '${oneLine.substring(0, 24)}…';
}

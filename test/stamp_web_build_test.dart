import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/stamp_web_build.dart';

const _index = '''<!DOCTYPE html>
<html><head><base href="/sio60.github.io-letters/"></head><body>
<script src="flutter_bootstrap.js" async></script>
</body></html>''';
const _bootstrap = '''_flutter.buildConfig = {
  "builds": [{"compileTarget":"dart2js","mainJsPath": "main.dart.js"}]
};
_flutter.loader.load();''';
const _main = 'window.example = "original JavaScript";';

void main() {
  late Directory fixture;
  File file(String name) => File.fromUri(fixture.uri.resolve(name));

  setUp(() {
    fixture = Directory.systemTemp.createTempSync('letter-web-stamp-');
    file('index.html').writeAsStringSync(_index);
    file('flutter_bootstrap.js').writeAsStringSync(_bootstrap);
    file('main.dart.js').writeAsStringSync(_main);
  });
  tearDown(() => fixture.deleteSync(recursive: true));

  test('versions both JavaScript URLs and preserves original JavaScript', () {
    const revision = '0123456789abcdef0123456789abcdef01234567';
    stampWebBuild(revision, buildDirectory: fixture.path);

    expect(file('main.$revision.dart.js').readAsStringSync(), _main);
    expect(
      file('flutter_bootstrap.$revision.js').readAsStringSync(),
      _bootstrap.replaceFirst('main.dart.js', 'main.$revision.dart.js'),
    );
    expect(
      file('index.html').readAsStringSync(),
      _index.replaceFirst(
        'flutter_bootstrap.js',
        'flutter_bootstrap.$revision.js',
      ),
    );
    expect(file('flutter_bootstrap.js').readAsStringSync(), _bootstrap);
    expect(file('main.dart.js').readAsStringSync(), _main);
  });

  test('rejects unsafe revisions without changing the build', () {
    for (final revision in [
      '',
      '../outside',
      r'..\outside',
      'bad/rev',
      'a\n',
    ]) {
      expect(
        () => stampWebBuild(revision, buildDirectory: fixture.path),
        throwsArgumentError,
      );
      expect(file('index.html').readAsStringSync(), _index);
      expect(file('flutter_bootstrap.js').readAsStringSync(), _bootstrap);
      expect(file('main.dart.js').readAsStringSync(), _main);
      expect(fixture.listSync(), hasLength(3));
    }
  });

  test(
    'missing inputs or required markers leave index and outputs untouched',
    () {
      const revision = 'test-release_1';
      for (final brokenBootstrap in [
        '_flutter.loader.load();',
        "{'mainJsPath': 'main.dart.js'}",
        '{"mainJsPath":"other.dart.js"}',
        '$_bootstrap\n$_bootstrap',
      ]) {
        file('flutter_bootstrap.js').writeAsStringSync(brokenBootstrap);
        expect(
          () => stampWebBuild(revision, buildDirectory: fixture.path),
          throwsFormatException,
        );
        expect(file('index.html').readAsStringSync(), _index);
        expect(fixture.listSync(), hasLength(3));
      }

      file('flutter_bootstrap.js').writeAsStringSync(_bootstrap);
      const missingScript = '<html><body>No bootstrap script</body></html>';
      file('index.html').writeAsStringSync(missingScript);
      expect(
        () => stampWebBuild(revision, buildDirectory: fixture.path),
        throwsFormatException,
      );
      expect(file('index.html').readAsStringSync(), missingScript);
      expect(fixture.listSync(), hasLength(3));

      file('index.html').writeAsStringSync(_index);
      file('main.dart.js').deleteSync();
      expect(
        () => stampWebBuild(revision, buildDirectory: fixture.path),
        throwsA(isA<FileSystemException>()),
      );
      expect(file('index.html').readAsStringSync(), _index);
      expect(fixture.listSync(), hasLength(2));
    },
  );
}

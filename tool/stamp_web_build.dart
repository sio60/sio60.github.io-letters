import 'dart:io';

/// Gives each deployment distinct JavaScript URLs while retaining build inputs.
void stampWebBuild(String revision, {String buildDirectory = 'build/web'}) {
  if (revision.isEmpty || RegExp(r'[^A-Za-z0-9_-]').hasMatch(revision)) {
    throw ArgumentError.value(
      revision,
      'revision',
      'Use only ASCII letters, digits, hyphens, and underscores.',
    );
  }

  final root = Directory(buildDirectory).absolute;
  File file(String name) => File.fromUri(root.uri.resolve(name));
  final indexFile = file('index.html');
  final bootstrapFile = file('flutter_bootstrap.js');
  final mainFile = file('main.dart.js');

  // Validate every input before creating outputs or changing the entry page.
  final index = indexFile.readAsStringSync();
  final bootstrap = bootstrapFile.readAsStringSync();
  final mainBytes = mainFile.readAsBytesSync();
  final mainMarker = RegExp(r'("mainJsPath"\s*:\s*)"main\.dart\.js"');
  final scriptMarker = RegExp(
    r'''(<script\b[^>]*\bsrc\s*=\s*["'])flutter_bootstrap\.js(["'][^>]*>)''',
  );
  if (mainMarker.allMatches(bootstrap).length != 1) {
    throw const FormatException(
      'Expected exactly one JSON "mainJsPath": "main.dart.js" marker.',
    );
  }
  if (scriptMarker.allMatches(index).length != 1) {
    throw const FormatException(
      'Expected exactly one script loading flutter_bootstrap.js.',
    );
  }

  final mainName = 'main.$revision.dart.js';
  final bootstrapName = 'flutter_bootstrap.$revision.js';
  final stampedBootstrap = bootstrap.replaceFirstMapped(
    mainMarker,
    (match) => '${match[1]}"$mainName"',
  );
  final stampedIndex = index.replaceFirstMapped(
    scriptMarker,
    (match) => '${match[1]}$bootstrapName${match[2]}',
  );

  file(mainName).writeAsBytesSync(mainBytes, flush: true);
  file(bootstrapName).writeAsStringSync(stampedBootstrap, flush: true);
  // Publish the references only after both referenced files are ready.
  indexFile.writeAsStringSync(stampedIndex, flush: true);
}

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/stamp_web_build.dart <revision> [buildDirectory]',
    );
    exitCode = 64;
    return;
  }
  try {
    stampWebBuild(
      arguments[0],
      buildDirectory: arguments.length == 2 ? arguments[1] : 'build/web',
    );
    stdout.writeln('Stamped web JavaScript URLs for ${arguments[0]}.');
  } catch (error) {
    stderr.writeln('Could not stamp web build: $error');
    exitCode = 1;
  }
}

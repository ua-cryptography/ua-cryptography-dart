// Pins the package to a release of ua-cryptography-rust: rewrites lib/src/bindings/native_release.dart with the
// version and the SHA-256 of every bare shared library, taken from the release's SHA256SUMS.
//
//   dart run tool/update_native_version.dart 0.1.7
//
// Then regenerate the bindings from that release's header: dart run tool/generate_bindings.dart
import 'dart:convert';
import 'dart:io';

const String releasesUrl = 'https://github.com/ua-cryptography/ua-cryptography-rust/releases/download';

// The line of the bare file of a target: ua-cryptography-<version>-<target>.<so|dylib|dll>.
RegExp bareLibraryLine(String version) =>
    RegExp('^([0-9a-f]{64})  ua-cryptography-${RegExp.escape(version)}-([a-z0-9-]+)\\.(?:so|dylib|dll)\$');

Future<void> main(List<String> arguments) async {
  if (arguments case [final version]) {
    final sums = await download(Uri.parse('$releasesUrl/v$version/SHA256SUMS'));
    final digests = <String, String>{};
    final bareLibrary = bareLibraryLine(version);
    for (final line in LineSplitter.split(sums)) {
      if (bareLibrary.firstMatch(line) case final match?) {
        digests[match[2]!] = match[1]!;
      }
    }
    if (digests.isEmpty) {
      throw StateError('The release v$version has no bare shared libraries in its SHA256SUMS.');
    }
    final output = File.fromUri(Platform.script.resolve('../lib/src/bindings/native_release.dart'));
    output.writeAsStringSync(nativeReleaseSource(version, digests));
    final format = await Process.run(Platform.resolvedExecutable, ['format', output.path]);
    if (format.exitCode != 0) {
      throw ProcessException('dart', ['format'], '${format.stderr}', format.exitCode);
    }
    stdout.writeln('Pinned $version: ${digests.keys.join(', ')}.');
  } else {
    throw ArgumentError('Usage: dart run tool/update_native_version.dart <version>');
  }
}

Future<String> download(Uri url) async {
  final client = HttpClient()..findProxy = HttpClient.findProxyFromEnvironment;
  try {
    final response = await (await client.getUrl(url)).close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

String nativeReleaseSource(String version, Map<String, String> digests) =>
    '''
// The pinned release of ua-cryptography-rust. Written by tool/update_native_version.dart; do not edit.

/// The release of ua-cryptography-rust whose library the build hook supplies and whose header the bindings come from.
const String nativeLibraryVersion = '$version';

/// The name of the code asset the build hook registers and the `@Native` bindings resolve.
const String nativeAssetName = 'src/bindings/ua_cryptography.g.dart';

/// The id of the code asset: `package:<package>/<name>`.
const String nativeAssetId = 'package:ua_cryptography/\$nativeAssetName';

/// The GitHub release the bare shared libraries are downloaded from.
const String nativeReleaseUrl = '$releasesUrl/v\$nativeLibraryVersion/';

/// The SHA-256 of the bare shared library of each target (`<os>-<arch>`), from the release's SHA256SUMS at the time
/// the version was pinned: a download is checked against these, never against the network's own SHA256SUMS.
const Map<String, String> nativeLibrarySha256 = {
${digests.entries.map((entry) => "  '${entry.key}': '${entry.value}',").join('\n')}
};

/// The bare file of the release for [target], e.g. `ua-cryptography-$version-macos-arm64.dylib`.
String nativeReleaseFileName(String target) {
  final extension = switch (target.split('-').first) {
    'android' || 'linux' => 'so',
    'ios' || 'macos' => 'dylib',
    _ => 'dll',
  };
  return 'ua-cryptography-\$nativeLibraryVersion-\$target.\$extension';
}
''';

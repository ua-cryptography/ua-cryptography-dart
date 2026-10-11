// Supplies the ua_cryptography shared library of ua-cryptography-rust for the target and registers it as the code
// asset the @Native bindings resolve.
//
// By default the library is downloaded from the GitHub release the package pins, checked against the SHA-256 the
// package carries and cached. Offline and development builds point the `local_library_dir` user-define of the root
// pubspec.yaml at a directory holding the library instead:
//
//   hooks:
//     user_defines:
//       ua_cryptography:
//         local_library_dir: ../ua-cryptography-rust/target/release
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';
import 'package:ua_cryptography/src/bindings/native_release.dart';

const String localLibraryDirKey = 'local_library_dir';

void main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }
    final code = input.config.code;
    if (code.linkModePreference == LinkModePreference.static) {
      throw UnsupportedError('ua_cryptography ships a dynamic library only; static linking was requested.');
    }
    final target = releaseTarget(code);
    final localLibraryDir = input.userDefines.path(localLibraryDirKey);
    final File source;
    if (localLibraryDir != null) {
      source = findLocalLibrary(Directory.fromUri(localLibraryDir), target, code.targetOS);
      output.dependencies.add(source.uri);
    } else {
      source = await downloadReleaseLibrary(target, Directory.fromUri(input.outputDirectoryShared));
    }

    // One directory per version and target: a target switch never overwrites a library still in use.
    final bundled = File.fromUri(
      input.outputDirectoryShared.resolve(
        '$nativeLibraryVersion/$target/${code.targetOS.dylibFileName('ua_cryptography')}',
      ),
    );
    bundled.parent.createSync(recursive: true);
    source.copySync(bundled.path);

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: nativeAssetName,
        linkMode: DynamicLoadingBundled(),
        file: bundled.uri,
      ),
    );
  });
}

/// The `<os>-<arch>` of the release files, e.g. `macos-arm64`, `ios-simulator-x64`, `android-arm`.
String releaseTarget(CodeConfig code) {
  final os = switch (code.targetOS) {
    OS.iOS when code.iOS.targetSdk == IOSSdk.iPhoneSimulator => 'ios-simulator',
    final other => other.name,
  };
  final target = '$os-${code.targetArchitecture.name}';
  if (!nativeLibrarySha256.containsKey(target)) {
    throw UnsupportedError(
      'ua_cryptography has no native library for $target; it has ${nativeLibrarySha256.keys.join(', ')}.',
    );
  }
  return target;
}

/// The library in [directory]: named as in the release, or as cargo names it (`target/<triple>/release`).
File findLocalLibrary(Directory directory, String target, OS targetOS) {
  final candidates = [
    File.fromUri(directory.uri.resolve(nativeReleaseFileName(target))),
    File.fromUri(directory.uri.resolve(targetOS.dylibFileName('ua_cryptography'))),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      return candidate;
    }
  }
  throw FileSystemException(
    'No ua_cryptography library for $target in $localLibraryDirKey; looked for '
    '${candidates.map((candidate) => candidate.path).join(' and ')}.',
    directory.path,
  );
}

/// The release file of [target] in the download cache of [cacheRoot], downloaded first when missing or damaged.
///
/// Throws a [FileSystemException] when the download does not have the pinned SHA-256.
Future<File> downloadReleaseLibrary(String target, Directory cacheRoot, {Uri? releaseUrl}) async {
  final fileName = nativeReleaseFileName(target);
  final expectedDigest = nativeLibrarySha256[target]!;
  final cached = File('${cacheRoot.path}/downloads/$fileName');
  if (cached.existsSync() && sha256OfFile(cached) == expectedDigest) {
    return cached;
  }
  cached.parent.createSync(recursive: true);
  // Written beside the cache entry and renamed into it only once checked: a cut download is never taken for one.
  final partial = File('${cached.path}.partial');
  final url = (releaseUrl ?? Uri.parse(nativeReleaseUrl)).resolve(fileName);
  final client = HttpClient()..findProxy = HttpClient.findProxyFromEnvironment;
  try {
    final response = await (await client.getUrl(url)).close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    await response.pipe(partial.openWrite());
  } on IOException catch (failure) {
    throw HttpException(
      'Cannot download $url ($failure). For an offline build set '
      'hooks.user_defines.ua_cryptography.$localLibraryDirKey in the root pubspec.yaml.',
      uri: url,
    );
  } finally {
    client.close();
  }
  final actualDigest = sha256OfFile(partial);
  if (actualDigest != expectedDigest) {
    partial.deleteSync();
    throw FileSystemException(
      'Refused $url: its SHA-256 is $actualDigest, the package pins $expectedDigest for ua-cryptography '
      '$nativeLibraryVersion.',
      cached.path,
    );
  }
  return partial.renameSync(cached.path);
}

String sha256OfFile(File file) => sha256.convert(file.readAsBytesSync()).toString();

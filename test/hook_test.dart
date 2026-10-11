import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';
import 'package:ua_cryptography/src/bindings/native_release.dart';

import '../hook/build.dart' as hook;

void main() {
  late Directory localLibraryDir;

  setUp(() {
    localLibraryDir = Directory.systemTemp.createTempSync('ua_cryptography_hook_test');
  });

  tearDown(() => localLibraryDir.deleteSync(recursive: true));

  PackageUserDefines localLibraryDirDefine() => PackageUserDefines(
    workspacePubspec: PackageUserDefinesSource(
      defines: {hook.localLibraryDirKey: localLibraryDir.path},
      basePath: localLibraryDir.uri,
    ),
  );

  File placeLibrary(String fileName, String content) =>
      File('${localLibraryDir.path}/$fileName')..writeAsStringSync(content);

  final targets = [
    (OS.android, Architecture.arm, null, 'android-arm.so', 'libua_cryptography.so'),
    (OS.iOS, Architecture.arm64, IOSSdk.iPhoneOS, 'ios-arm64.dylib', 'libua_cryptography.dylib'),
    (OS.iOS, Architecture.x64, IOSSdk.iPhoneSimulator, 'ios-simulator-x64.dylib', 'libua_cryptography.dylib'),
    (OS.windows, Architecture.arm64, null, 'windows-arm64.dll', 'ua_cryptography.dll'),
  ];
  for (final (os, architecture, sdk, releaseSuffix, bundledName) in targets) {
    test('$os $architecture${sdk == null ? '' : ' $sdk'}: the release-named file, bundled as $bundledName', () async {
      placeLibrary('ua-cryptography-$nativeLibraryVersion-$releaseSuffix', releaseSuffix);
      await testCodeBuildHook(
        mainMethod: hook.main,
        targetOS: os,
        targetArchitecture: architecture,
        targetIOSSdk: sdk ?? IOSSdk.iPhoneOS,
        userDefines: localLibraryDirDefine(),
        check: (input, output) {
          final asset = output.assets.code.single;
          expect(asset.id, nativeAssetId);
          expect(asset.linkMode, DynamicLoadingBundled());
          expect(asset.file!.pathSegments.last, bundledName);
          expect(File.fromUri(asset.file!).readAsStringSync(), releaseSuffix);
        },
      );
    });
  }

  test('a cargo-named library serves when no release-named one is there', () async {
    placeLibrary(OS.current.dylibFileName('ua_cryptography'), 'cargo');
    await testCodeBuildHook(
      mainMethod: hook.main,
      userDefines: localLibraryDirDefine(),
      check: (input, output) {
        expect(File.fromUri(output.assets.code.single.file!).readAsStringSync(), 'cargo');
      },
    );
  });

  test('a target the release has no library for is refused', () {
    expect(
      testCodeBuildHook(
        mainMethod: hook.main,
        targetOS: OS.linux,
        targetArchitecture: Architecture.riscv64,
        userDefines: localLibraryDirDefine(),
        check: (input, output) {},
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });

  group('download', () {
    late HttpServer server;
    late List<String> requestedPaths;
    late Directory cacheRoot;
    const target = 'linux-x64';

    setUp(() async {
      requestedPaths = [];
      cacheRoot = Directory('${localLibraryDir.path}/cache');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        requestedPaths.add(request.uri.path);
        request.response
          ..write('not the library of the release')
          ..close();
      });
    });

    tearDown(() => server.close(force: true));

    Uri releaseUrl() => Uri.parse('http://${server.address.host}:${server.port}/release/');

    test('a download without the pinned SHA-256 is refused and not cached', () async {
      await expectLater(
        hook.downloadReleaseLibrary(target, cacheRoot, releaseUrl: releaseUrl()),
        throwsA(isA<FileSystemException>().having((error) => error.message, 'message', contains('SHA-256'))),
      );
      expect(requestedPaths, ['/release/${nativeReleaseFileName(target)}']);
      expect(cacheRoot.listSync(recursive: true).whereType<File>(), isEmpty);
    });

    test('a damaged cache entry is downloaded again', () async {
      File('${cacheRoot.path}/downloads/${nativeReleaseFileName(target)}')
        ..createSync(recursive: true)
        ..writeAsStringSync('damaged');
      await expectLater(
        hook.downloadReleaseLibrary(target, cacheRoot, releaseUrl: releaseUrl()),
        throwsA(isA<FileSystemException>()),
      );
      expect(requestedPaths, hasLength(1));
    });

    test('an unreachable release names the offline user-define', () async {
      final closedUrl = releaseUrl();
      await server.close(force: true);
      await expectLater(
        hook.downloadReleaseLibrary(target, cacheRoot, releaseUrl: closedUrl),
        throwsA(isA<HttpException>().having((error) => error.message, 'message', contains(hook.localLibraryDirKey))),
      );
    });
  });

  test('a missing library names the files looked for', () {
    expect(
      testCodeBuildHook(mainMethod: hook.main, userDefines: localLibraryDirDefine(), check: (input, output) {}),
      throwsA(isA<FileSystemException>().having((error) => error.message, 'message', contains('looked for'))),
    );
  });
}

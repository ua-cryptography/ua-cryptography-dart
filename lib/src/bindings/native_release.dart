// The pinned release of ua-cryptography-rust. Written by tool/update_native_version.dart; do not edit.

/// The release of ua-cryptography-rust whose library the build hook supplies and whose header the bindings come from.
const String nativeLibraryVersion = '0.1.6';

/// The name of the code asset the build hook registers and the `@Native` bindings resolve.
const String nativeAssetName = 'src/bindings/ua_cryptography.g.dart';

/// The id of the code asset: `package:<package>/<name>`.
const String nativeAssetId = 'package:ua_cryptography/$nativeAssetName';

/// The GitHub release the bare shared libraries are downloaded from.
const String nativeReleaseUrl =
    'https://github.com/ua-cryptography/ua-cryptography-rust/releases/download/v$nativeLibraryVersion/';

/// The SHA-256 of the bare shared library of each target (`<os>-<arch>`), from the release's SHA256SUMS at the time
/// the version was pinned: a download is checked against these, never against the network's own SHA256SUMS.
const Map<String, String> nativeLibrarySha256 = {
  'android-arm': 'bd52a5786844dd550b57589a3f81e91d8aa7984ae04be2cef3cfebc2e04161b6',
  'android-arm64': '92919869cb5b452a8111bc5f13919359b5b01b3f05ec0a57d6e90e18a2eed12b',
  'android-ia32': 'b9a68ac1509a1fa7116a29ea4ce72cae53e21f11d528c04414d85ce86ae1ec60',
  'android-x64': '171f61e0609a2e7f95e7436e3ea540ce5d8856e22595ec11a409f335996cd6ea',
  'ios-arm64': 'fb527d2cd6dcf50b13724715de014e7b546cf8528b21160dfee1b678555ecc11',
  'ios-simulator-arm64': '5c2cb3738eeb45a9f4fa418d592d897d6f7a331e26c62f34cee4707b07b73122',
  'ios-simulator-x64': 'f8aeb486ab234b2aff08d2033c33fe95ccddc0169b7afc0e4152633a74cbd408',
  'linux-arm64': 'd5b5ed9ecdbf6330d058665aa36b62e4630ad39c9791adebfe190e0b5807d2ec',
  'linux-x64': '5f75ef9ccaf00624e395177248710b6f3caef9237e94f444ff87e731231235d9',
  'macos-arm64': 'f46c1d21be5a748616c9fcc8aacde01ce2648e2e35f8f183e392077a779262fd',
  'macos-x64': '86953612215bb4b0f317337b237b19422ab4a59cb0af563d244f671165f6539d',
  'windows-arm64': 'be72b68d38e7173cdce3611c425e8a99dfc192dbfc09c01103c9edb4a88e792a',
  'windows-x64': '3722ed20b71a43468abbec3e0dfd2469c8ab4ce382d29651d8d578b9cc831627',
};

/// The bare file of the release for [target], e.g. `ua-cryptography-0.1.6-macos-arm64.dylib`.
String nativeReleaseFileName(String target) {
  final extension = switch (target.split('-').first) {
    'android' || 'linux' => 'so',
    'ios' || 'macos' => 'dylib',
    _ => 'dll',
  };
  return 'ua-cryptography-$nativeLibraryVersion-$target.$extension';
}

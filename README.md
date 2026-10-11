# ua_cryptography

Ukrainian national cryptography for Dart and Flutter: DSTU 7564 (Kupyna), JKS key stores with DSTU 4145 keys, and
signing and verifying the electronic signatures of the Ukrainian PKI — CAdES (`.p7s`, PrivatBank's `.sig`), XAdES
(`.xml`), ASiC-S (`.asics`) and ASiC-E (`.asice`, «Дія.Підпис») at levels B, T and LT.

The package binds the `ua_cryptography` native library of
[ua-cryptography-rust](https://github.com/ua-cryptography/ua-cryptography-rust), a port of the
[C# reference implementation](https://github.com/ua-cryptography/ua-cryptography-csharp). The library is supplied by
a [build hook](https://dart.dev/tools/hooks): nothing to install, no CocoaPods, Gradle or CMake setup.

## Platforms

| Platform | Architectures | Minimum |
|---|---|---|
| Android | arm64-v8a, armeabi-v7a, x86_64, x86 | API 24 (Flutter 3.38) |
| iOS | devices arm64; simulators arm64, x86_64 | iOS 13 (arm64 simulators: 14) |
| macOS | arm64, x86_64 | macOS 11 |
| Linux | x64, arm64 | glibc 2.35 |
| Windows | x64, arm64 | Windows 10 |

Dart 3.10 / Flutter 3.38 or later. The package also works in plain Dart on the desktop (`dart run`, `dart test`).
Web is not supported: Flutter web has no FFI (see [Not yet](#not-yet)).

## Installation

```yaml
dependencies:
  ua_cryptography: ^0.1.0
```

On the first build the hook downloads the shared library of the target (3–5 MB) from the GitHub release of
ua-cryptography-rust the package pins, checks it against the SHA-256 the package carries, and caches it. A file with
another digest is refused. Flutter bundles the library into the app like any other native code.

### Offline builds

To build without network access, or against a library built from source, point the `local_library_dir` user-define of
your app's `pubspec.yaml` at a directory holding the library:

```yaml
hooks:
  user_defines:
    ua_cryptography:
      local_library_dir: ../ua-cryptography-rust/target/release
```

The hook takes the release file of the target there (e.g. `ua-cryptography-0.1.6-ios-arm64.dylib`, as attached to the
[release](https://github.com/ua-cryptography/ua-cryptography-rust/releases)), else the file as cargo names it
(`libua_cryptography.so`, `libua_cryptography.dylib`, `ua_cryptography.dll`). A directory of release files serves
every target; a cargo output directory serves the one it was built for. `tool/build_native_libraries.sh` builds the
release files of every target the machine can build from a checkout of ua-cryptography-rust.

The loaded library must be of the release the package pins: the first call refuses another version with a
`StateError`.

## Usage

```dart
import 'package:ua_cryptography/ua_cryptography.dart';
```

### Verify a signature

```dart
final report = await verify(
  signatureBytes,                          // .sig / .p7s, .xml, .asics, .asice
  data: [NamedBytes('contract.pdf', pdf)], // only for a detached signature
  trustAnchors: [czoRoot, nbuRoot],        // trusted roots: DER, PEM or a .p7b bundle each
  certificates: [privatBankBundle],        // CA, time-stamping and OCSP certificates the signature lacks
  isOnline: true,                          // ask the OCSP responders the certificates name
);

print('${report.format}: ${report.isValid ? 'valid' : 'NOT valid'}, ${report.warningCount} warnings');
for (final signature in report.signatures.where((summary) => !summary.isContainer)) {
  print('${signature.signer?.subjectName} at ${signature.timestampTime ?? signature.signingTime}');
  for (final check in signature.checks.where((check) => check.status != CheckOutcome.passed)) {
    print('  ${check.status.name}: ${check.name}: ${check.details}');
  }
}
```

An invalid signature is a report with `isValid == false`, not an exception. A check that could not be established —
typically the revocation status of a certificate when the signature carries none and `isOnline` is off — is a
warning: the signature stays valid.

### Sign a document

```dart
final signature = await sign(
  keyStoreBytes,                             // a JKS key store
  password,
  [NamedBytes('contract.pdf', pdf)],         // CAdES and ASiC-S sign one file
  options: const SigningOptions(
    format: SignatureFormat.asicE,           // cades (default), xades, asicS, asicE
    level: SignatureLevel.t,                 // b (default, offline), t, lt
    hash: SignatureHash.dstu7564,            // or gost34311
  ),
);
```

Level T asks the time-stamping service the signer's certificate names (or `SigningOptions.tsaUrl`) for a time-stamp
over the hash of the signature; level LT also embeds the CA certificates and OCSP responses. The document and the key
never leave the device. CAdES is enveloped unless `isDetached: true`.

### Key stores and certificates

```dart
// A JKS key store with a new DSTU 4145 key (curve m = 257 of table Г.1) and its self-signed certificate.
final created = await createKeyStore(const KeyStoreRequest(subject: 'CN=Test signer,O=Test,C=UA'), password);

for (final entry in getKeyStoreEntries(created.keyStore, password)) {
  print('${entry.alias}: ${entry.kind.name}, ${entry.certificates.first.subjectName}');
}

final certificate = getCertificate(created.keyStore, password); // DER of the signing key's certificate
final details = getCertificateDetails(certificate);              // DER, PEM or base64
print('${details.subjectName}, issued by ${details.issuerName}, valid to ${details.validTo}');
print('time-stamping: ${details.timeStampUrls}, OCSP: ${details.ocspUrls}');
```

### Hashes

```dart
final hash = dstu7564CalculateHash(data, 256); // Kupyna-256; also 384 and 512
```

### Errors

Every refusal of the native library is a `UaCryptographyException`, sealed, one subclass per status, with the
library's message:

| Exception | When |
|---|---|
| `InvalidArgumentException` | a wrong length, an unknown curve degree or hash size, options that do not fit the format |
| `UnreadableInputException` | a key store, certificate or signature that does not parse |
| `WrongPasswordException` | the key store or its key does not open with the password |
| `AuthenticationFailedException` | an authenticated ciphertext or a wrapped key is not the one tagged |
| `ServiceFailureException` | a time-stamping, OCSP or certificate download service failed |
| `InternalException` | a defect of the native library |

### Threads

`sign`, `verify` and `createKeyStore` return `Future`s and run on a separate isolate: levels T and LT and online
verification reach network services over blocking sockets. The other functions are synchronous and fast. The native
library is thread-safe.

## Example

[`example/`](example) is a Flutter app with the three tabs of
[ua-cryptography-typescript](https://github.com/ua-cryptography/ua-cryptography-typescript): **Verify** a signed file,
**Sign** a document with a `.jks` key (or a synthetic test key), and the trusted **Certificates** (the public roots of
the ЦЗО and the НБУ, the «Дія» and PrivatBank CAs, built in; more can be added). Its integration tests run the same
flows on a device:

```sh
cd example
flutter run
flutter test integration_test -d <device>
```

## Not yet

The native library also has GOST 28147-89, GOST 34.311-95, DSTU 7624 (Kalyna: block, ECB, CBC, CFB, OFB, CTR, CMAC,
CCM, GCM, GMAC, XTS, KW), DSTU 4145 primitives (key pairs, signing a hash, encoding) and hashes fed in parts; their Dart
API is to come. Web support through the npm package [`ua-cryptography`](https://www.npmjs.com/package/ua-cryptography)
(WebAssembly) is possible later; the public API holds no `dart:ffi` types to keep that open.

## Development

```sh
dart test                                       # the hook downloads the pinned library
dart analyze --fatal-infos && dart format --set-exit-if-changed .
dart run tool/update_native_version.dart 0.1.7 # pin another release: version and SHA-256 table
dart run tool/generate_bindings.dart            # regenerate lib/src/bindings/ua_cryptography.g.dart from its header
```

Tests use synthetic keys generated at run time and public CA certificates only: no real signature, key or certificate
of a person is part of this repository.

## License

[MIT](LICENSE).

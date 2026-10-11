import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import '../bindings/ua_cryptography.g.dart';
import '../exceptions/ua_cryptography_exception.dart';
import '../native/native_call.dart';
import 'named_bytes.dart';
import 'native_codes.dart';
import 'signing_options.dart';

/// Signs [files] with the key [alias] of [keyStore] (without [alias], its one signing key), as [options] say, and
/// returns the signature: the `.p7s` / `.sig`, the `.xml`, or the `.asics` / `.asice` container.
///
/// CAdES and ASiC-S sign one file. [certificates] complete the signer's chain (DER, PEM or a bundle each). Runs on a
/// separate isolate: levels T and LT ask the time-stamping service, OCSP responders and caIssuers over the network.
///
/// Throws a [WrongPasswordException] when the store does not open with [password], an [UnreadableInputException]
/// when it does not parse, an [InvalidArgumentException] for options that do not fit the format or the key, and a
/// [ServiceFailureException] when a service of level T or LT does not answer.
Future<Uint8List> sign(
  Uint8List keyStore,
  String password,
  List<NamedBytes> files, {
  String? alias,
  SigningOptions options = const SigningOptions(),
  List<Uint8List> certificates = const [],
}) => Isolate.run(
  () => callNative((arena) {
    final nativeOptions = arena<UaSigningOptions>();
    nativeOptions.ref
      ..format = signatureFormatCode(options.format)
      ..level = signatureLevelCode(options.level)
      ..hash = signatureHashCode(options.hash)
      ..is_detached = options.isDetached
      ..has_content_time_stamp = options.hasContentTimeStamp
      ..tsa_url = arena.lendOptionalString(options.tsaUrl)
      ..ocsp_url = arena.lendOptionalString(options.ocspUrl);
    return callForBytes(
      arena,
      (signature, errorMessage) => ua_sign(
        arena.lend(keyStore),
        arena.lendString(password),
        arena.lendOptionalString(alias),
        arena.lendFiles(files),
        files.length,
        arena.lendByteArrays(certificates),
        certificates.length,
        nativeOptions,
        signature,
        errorMessage,
      ),
    );
  }),
);

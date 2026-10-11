import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import '../bindings/ua_cryptography.g.dart';
import '../exceptions/ua_cryptography_exception.dart';
import '../native/native_call.dart';
import '../reports/verification_summary.dart';
import 'named_bytes.dart';

/// Verifies [signature] of any format — CAdES (`.p7s`, `.sig`), XAdES (`.xml`), ASiC-S, ASiC-E — and reports every
/// check. An invalid signature is a report with [VerificationSummary.isValid] false, not an exception.
///
/// * [data] — the data of a detached signature under the names its references use; one file stands for any name
/// * [trustAnchors] — trusted roots (DER, PEM or a bundle each); a path must end at one of them
/// * [certificates] — further certificates for the paths (CAs, time-stamping and OCSP services)
/// * [isOnline] — ask the OCSP responders the certificates name and download missing CA certificates by caIssuers
///
/// Runs on a separate isolate. Throws an [UnreadableInputException] when [signature] is of no format the library knows.
Future<VerificationSummary> verify(
  Uint8List signature, {
  List<NamedBytes> data = const [],
  List<Uint8List> trustAnchors = const [],
  List<Uint8List> certificates = const [],
  bool isOnline = false,
}) => Isolate.run(() {
  final report = callNative(
    (arena) => callForBytes(
      arena,
      (reportJson, errorMessage) => ua_verify(
        arena.lend(signature),
        arena.lendFiles(data),
        data.length,
        arena.lendByteArrays(trustAnchors),
        trustAnchors.length,
        arena.lendByteArrays(certificates),
        certificates.length,
        isOnline,
        reportJson,
        errorMessage,
      ),
    ),
  );
  return VerificationSummary.fromJsonText(utf8.decode(report));
});

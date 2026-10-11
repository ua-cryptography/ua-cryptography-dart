import 'dart:convert';
import 'dart:typed_data';

import '../bindings/ua_cryptography.g.dart';
import '../exceptions/ua_cryptography_exception.dart';
import '../native/native_call.dart';
import '../reports/certificate_details.dart';
import '../reports/json_fields.dart';

/// What [certificate] says; it may be DER, PEM or base64.
///
/// Throws an [UnreadableInputException] when [certificate] does not parse as an X.509 certificate.
CertificateDetails getCertificateDetails(Uint8List certificate) {
  final json = callNative(
    (arena) => callForBytes(
      arena,
      (details, errorMessage) => ua_get_certificate_details(arena.lend(certificate), details, errorMessage),
    ),
  );
  return CertificateDetails.fromJson(JsonFields.of(jsonDecode(utf8.decode(json)), 'The certificate details'));
}

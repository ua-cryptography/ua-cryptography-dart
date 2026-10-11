import 'signature_format.dart';
import 'signature_hash.dart';
import 'signature_level.dart';

/// How `sign` signs.
final class SigningOptions {
  /// The format; CAdES and ASiC-S sign one file.
  final SignatureFormat format;

  /// B offline; T asks the time-stamping service, LT also the OCSP responders and caIssuers.
  final SignatureLevel level;

  /// The hash of the signature.
  final SignatureHash hash;

  /// CAdES without the data inside.
  final bool isDetached;

  /// CAdES and ASiC-S: also time-stamp the data itself (asks the time-stamping service).
  final bool hasContentTimeStamp;

  /// The time-stamping service; null: the one the signer's certificate names.
  final String? tsaUrl;

  /// The OCSP responder for every certificate; null: each certificate's own.
  final String? ocspUrl;

  /// Options with the defaults of the national PKI: CAdES-B, enveloped, DSTU 7564-256.
  const SigningOptions({
    this.format = SignatureFormat.cades,
    this.level = SignatureLevel.b,
    this.hash = SignatureHash.dstu7564,
    this.isDetached = false,
    this.hasContentTimeStamp = false,
    this.tsaUrl,
    this.ocspUrl,
  });
}

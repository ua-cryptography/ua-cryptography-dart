import 'signature_hash.dart';

/// A new JKS key store with one DSTU 4145 key on a curve of table Г.1 and its self-signed certificate.
final class KeyStoreRequest {
  /// The subject, e.g. `CN=Name,O=Organization,C=UA`.
  final String subject;

  /// The alias of the key entry.
  final String alias;

  /// The degree m of the curve of table Г.1; 257 is the one of the national PKI.
  final int m;

  /// How many days the certificate is valid.
  final int validityDays;

  /// The hash the certificate is signed over.
  final SignatureHash signatureHash;

  /// A request for a key of [subject]; the key is named `key`, on the curve m = 257, for a year.
  const KeyStoreRequest({
    required this.subject,
    this.alias = 'key',
    this.m = 257,
    this.validityDays = 365,
    this.signatureHash = SignatureHash.dstu7564,
  });
}

import 'certificate_details.dart';
import 'json_fields.dart';
import 'named_algorithm.dart';
import 'signed_reference.dart';
import 'verification_check.dart';

/// The verification of one signature, or of an ASiC container's structure ([isContainer]).
final class SignatureSummary {
  /// The title the library gives the structure report of a container.
  static const String containerTitle = 'container';

  /// What was verified, e.g. `CAdES signature`.
  final String title;

  /// The format and level found, e.g. `XAdES-B-LT` or `CAdES-T`.
  final String? level;

  /// `detached` or `enveloped`.
  final String? packaging;

  /// The signature algorithm.
  final NamedAlgorithm? signatureAlgorithm;

  /// The hash the signature is computed over.
  final NamedAlgorithm? digestAlgorithm;

  /// The signing time the signer claims, UTC.
  final DateTime? signingTime;

  /// The time of the signature time-stamp, when present and valid, UTC.
  final DateTime? timestampTime;

  /// The time the certificates were validated at: the time-stamp, else the claimed time, else now.
  final DateTime? validationTime;

  /// No check failed.
  final bool isValid;

  /// A check ended with a warning.
  final bool hasWarnings;

  /// The signer's certificate, when found.
  final CertificateDetails? signer;

  /// What the signature covers.
  final List<SignedReference> references;

  /// Every check in the order made.
  final List<VerificationCheck> checks;

  /// The summary as a report gives it.
  const SignatureSummary({
    required this.title,
    required this.level,
    required this.packaging,
    required this.signatureAlgorithm,
    required this.digestAlgorithm,
    required this.signingTime,
    required this.timestampTime,
    required this.validationTime,
    required this.isValid,
    required this.hasWarnings,
    required this.signer,
    required this.references,
    required this.checks,
  });

  /// Reads the `signature_summary` of a report.
  factory SignatureSummary.fromJson(Map<String, Object?> map) {
    final json = JsonFields(map);
    return SignatureSummary(
      title: json.string('title'),
      level: json.optionalString('level'),
      packaging: json.optionalString('packaging'),
      signatureAlgorithm: switch (json.optionalObject('signature_algorithm')) {
        final JsonFields algorithm => NamedAlgorithm.fromJson(algorithm),
        null => null,
      },
      digestAlgorithm: switch (json.optionalObject('digest_algorithm')) {
        final JsonFields algorithm => NamedAlgorithm.fromJson(algorithm),
        null => null,
      },
      signingTime: json.optionalTime('signing_time'),
      timestampTime: json.optionalTime('timestamp_time'),
      validationTime: json.optionalTime('validation_time'),
      isValid: json.boolean('is_valid'),
      hasWarnings: json.boolean('has_warnings'),
      signer: switch (json.optionalObject('signer')) {
        final JsonFields signer => CertificateDetails.fromJson(signer),
        null => null,
      },
      references: json.objects('references', SignedReference.fromJson),
      checks: json.objects('checks', VerificationCheck.fromJson),
    );
  }

  /// The structure report of an ASiC container, not a signature.
  bool get isContainer => title == containerTitle;
}

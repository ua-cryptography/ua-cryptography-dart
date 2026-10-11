import 'dart:convert';

import 'json_fields.dart';
import 'signature_summary.dart';

/// The verification of a signed file: the verdict and a summary per signature.
final class VerificationSummary {
  /// The format recognised, e.g. `ASiC-E`.
  final String format;

  /// Every signature holds and none failed a check.
  final bool isValid;

  /// The signatures, the container's structure report excluded.
  final int signatureCount;

  /// The checks that ended with a warning.
  final int warningCount;

  /// The checks that failed.
  final int failureCount;

  /// When the verification was made, UTC.
  final DateTime verifiedAt;

  /// The names of the files the signatures cover.
  final List<String> signedFiles;

  /// The structure report of a container first, then each signature.
  final List<SignatureSummary> signatures;

  /// The summary as a report gives it.
  const VerificationSummary({
    required this.format,
    required this.isValid,
    required this.signatureCount,
    required this.warningCount,
    required this.failureCount,
    required this.verifiedAt,
    required this.signedFiles,
    required this.signatures,
  });

  /// Reads the `verification_summary` of a report.
  factory VerificationSummary.fromJson(Map<String, Object?> map) {
    final json = JsonFields(map);
    return VerificationSummary(
      format: json.string('format'),
      isValid: json.boolean('is_valid'),
      signatureCount: json.integer('signature_count'),
      warningCount: json.integer('warning_count'),
      failureCount: json.integer('failure_count'),
      verifiedAt: json.time('verified_at'),
      signedFiles: json.strings('signed_files'),
      signatures: json.objects('signatures', SignatureSummary.fromJson),
    );
  }

  /// Reads the JSON report `ua_verify` writes.
  factory VerificationSummary.fromJsonText(String text) =>
      VerificationSummary.fromJson(JsonFields.of(jsonDecode(text), 'The verification report'));

  /// Valid, with a check that ended with a warning.
  bool get hasWarnings => isValid && warningCount > 0;
}

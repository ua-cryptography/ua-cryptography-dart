import 'json_fields.dart';
import 'named_algorithm.dart';

/// What a signature covers: a XAdES reference, or `content` in CAdES.
final class SignedReference {
  /// The reference URI, or `content`.
  final String name;

  /// The hash of the digest.
  final NamedAlgorithm digestAlgorithm;

  /// The digest, upper-case hex.
  final String digest;

  /// The reference [name] with its [digest].
  const SignedReference({required this.name, required this.digestAlgorithm, required this.digest});

  /// Reads the `reference_row` of a report.
  factory SignedReference.fromJson(Map<String, Object?> map) {
    final json = JsonFields(map);
    return SignedReference(
      name: json.string('name'),
      digestAlgorithm: NamedAlgorithm.fromJson(json.object('digest_algorithm')),
      digest: json.string('digest'),
    );
  }
}

import 'json_fields.dart';

/// An algorithm as a signature or a certificate names it, with its readable name.
final class NamedAlgorithm {
  /// An OID in CMS and X.509, a URI in XML-DSig.
  final String identifier;

  /// E.g. `DSTU 7564-256`; the identifier itself when it has no name.
  final String name;

  /// The algorithm [identifier], read as [name].
  const NamedAlgorithm({required this.identifier, required this.name});

  /// Reads the `algorithm_row` of a report.
  factory NamedAlgorithm.fromJson(Map<String, Object?> map) {
    final json = JsonFields(map);
    return NamedAlgorithm(identifier: json.string('identifier'), name: json.string('name'));
  }

  @override
  String toString() => name;
}

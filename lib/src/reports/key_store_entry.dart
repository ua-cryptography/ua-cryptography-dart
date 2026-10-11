import 'certificate_details.dart';
import 'json_fields.dart';
import 'key_store_entry_kind.dart';

/// One entry of a key store.
final class KeyStoreEntry {
  /// The alias.
  final String alias;

  /// A private key or a trusted certificate.
  final KeyStoreEntryKind kind;

  /// When the entry was created, UTC.
  final DateTime created;

  /// The chain of a private key as stored, or the trusted certificate.
  final List<CertificateDetails> certificates;

  /// The entry [alias].
  const KeyStoreEntry({required this.alias, required this.kind, required this.created, required this.certificates});

  /// Reads the `key_store_entry_row` of a report.
  factory KeyStoreEntry.fromJson(Map<String, Object?> map) {
    final json = JsonFields(map);
    return KeyStoreEntry(
      alias: json.string('alias'),
      kind: KeyStoreEntryKind.fromJson(json.string('kind')),
      created: json.time('created'),
      certificates: json.objects('certificates', CertificateDetails.fromJson),
    );
  }
}

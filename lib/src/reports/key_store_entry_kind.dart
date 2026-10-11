/// The kind of a JKS entry.
enum KeyStoreEntryKind {
  /// A protected private key with its chain.
  privateKey,

  /// A trusted certificate.
  trustedCertificate;

  /// Reads the `kind` of an entry: `private_key` or `trusted_certificate`.
  static KeyStoreEntryKind fromJson(String kind) => switch (kind) {
    'private_key' => privateKey,
    'trusted_certificate' => trustedCertificate,
    _ => throw FormatException('Unknown key store entry kind "$kind"'),
  };
}

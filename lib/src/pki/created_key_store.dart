import 'dart:typed_data';

/// A key store made by `createKeyStore` and the certificate of its key.
final class CreatedKeyStore {
  /// The JKS bytes.
  final Uint8List keyStore;

  /// The self-signed certificate, DER.
  final Uint8List certificate;

  /// The store [keyStore] holding the key of [certificate].
  const CreatedKeyStore(this.keyStore, this.certificate);
}

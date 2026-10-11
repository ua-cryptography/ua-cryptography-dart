/// The hash a PKI signature and a certificate are computed over.
enum SignatureHash {
  /// DSTU 7564-256 (Kupyna), the hash of the current national PKI.
  dstu7564,

  /// GOST 34.311-95 with the DKE of the key.
  gost34311,
}

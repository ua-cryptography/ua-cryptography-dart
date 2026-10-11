/// The level of a signature.
enum SignatureLevel {
  /// The basic signature, made offline.
  b,

  /// With a signature time-stamp from the time-stamping service.
  t,

  /// With the CA certificates and OCSP responses too: XAdES-B-LT, CAdES-X Long.
  lt,
}

import '../bindings/ua_cryptography.g.dart';
import 'signature_format.dart';
import 'signature_hash.dart';
import 'signature_level.dart';

/// The C ABI's number of [format].
int signatureFormatCode(SignatureFormat format) => switch (format) {
  SignatureFormat.cades => UA_SIGNATURE_FORMAT_CADES,
  SignatureFormat.xades => UA_SIGNATURE_FORMAT_XADES,
  SignatureFormat.asicS => UA_SIGNATURE_FORMAT_ASIC_S,
  SignatureFormat.asicE => UA_SIGNATURE_FORMAT_ASIC_E,
};

/// The C ABI's number of [level].
int signatureLevelCode(SignatureLevel level) => switch (level) {
  SignatureLevel.b => UA_SIGNATURE_LEVEL_B,
  SignatureLevel.t => UA_SIGNATURE_LEVEL_T,
  SignatureLevel.lt => UA_SIGNATURE_LEVEL_LT,
};

/// The C ABI's number of [hash].
int signatureHashCode(SignatureHash hash) => switch (hash) {
  SignatureHash.dstu7564 => UA_SIGNATURE_HASH_DSTU7564,
  SignatureHash.gost34311 => UA_SIGNATURE_HASH_GOST34311,
};

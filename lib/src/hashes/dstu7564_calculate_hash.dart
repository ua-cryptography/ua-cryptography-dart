import 'dart:typed_data';

import '../bindings/ua_cryptography.g.dart';
import '../exceptions/ua_cryptography_exception.dart';
import '../native/native_call.dart';

/// DSTU 7564:2014 "Kupyna" of [data]: [hashBits] / 8 bytes, as the standard writes them.
///
/// [hashBits] is 256, 384 or 512; 256 is the hash of the national PKI.
///
/// Throws an [InvalidArgumentException] for any other [hashBits].
Uint8List dstu7564CalculateHash(Uint8List data, int hashBits) => callNative(
  (arena) => callForBytes(
    arena,
    (hash, errorMessage) => ua_dstu7564_calculate_hash(arena.lend(data), hashBits, hash, errorMessage),
  ),
);

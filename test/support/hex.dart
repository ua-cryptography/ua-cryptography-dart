import 'dart:typed_data';

/// [bytes] as upper-case hex.
String toHex(Uint8List bytes) => bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

/// The bytes of the [hex] string.
Uint8List fromHex(String hex) => Uint8List.fromList([
  for (var index = 0; index < hex.length; index += 2) int.parse(hex.substring(index, index + 2), radix: 16),
]);

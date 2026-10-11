import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import '../bindings/ua_cryptography.g.dart';
import '../exceptions/ua_cryptography_exception.dart';
import '../native/native_call.dart';
import '../reports/json_fields.dart';
import '../reports/key_store_entry.dart';
import 'created_key_store.dart';
import 'key_store_request.dart';
import 'native_codes.dart';

/// A new JKS key store protected by [password] (the key too), with a DSTU 4145 key generated from the operating
/// system's random source and its self-signed certificate. Runs on a separate isolate.
///
/// Throws an [InvalidArgumentException] for a curve degree m that table Г.1 does not list, or a subject that does not
/// parse.
Future<CreatedKeyStore> createKeyStore(KeyStoreRequest request, String password) => Isolate.run(
  () => callNative((arena) {
    final nativeRequest = arena<UaKeyStoreRequest>();
    nativeRequest.ref
      ..subject = arena.lendString(request.subject)
      ..alias = arena.lendString(request.alias)
      ..m = request.m
      ..validity_days = request.validityDays
      ..signature_hash = signatureHashCode(request.signatureHash);
    final keyStore = arena.receiveBuffer();
    final certificate = arena.receiveBuffer();
    final errorMessage = arena.receiveBuffer();
    throwOnRefusal(
      ua_create_key_store(nativeRequest, arena.lendString(password), keyStore, certificate, errorMessage),
      errorMessage,
    );
    return CreatedKeyStore(copyBuffer(keyStore), copyBuffer(certificate));
  }),
);

/// The certificate (DER) of the signing key [alias] of [keyStore]; without [alias], of its one signing key.
///
/// Throws an [UnreadableInputException] when [keyStore] is not a JKS store, a [WrongPasswordException] when it does not
/// open with [password], and an [InvalidArgumentException] when it has no such key, or several and no [alias].
Uint8List getCertificate(Uint8List keyStore, String password, {String? alias}) => callNative(
  (arena) => callForBytes(
    arena,
    (certificate, errorMessage) => ua_get_certificate(
      arena.lend(keyStore),
      arena.lendString(password),
      arena.lendOptionalString(alias),
      certificate,
      errorMessage,
    ),
  ),
);

/// The entries of [keyStore], opened with [password].
///
/// Throws an [UnreadableInputException] when [keyStore] is not a JKS store and a [WrongPasswordException] when it does
/// not open with [password].
List<KeyStoreEntry> getKeyStoreEntries(Uint8List keyStore, String password) {
  final json = callNative(
    (arena) => callForBytes(
      arena,
      (entries, errorMessage) =>
          ua_get_key_store_entries(arena.lend(keyStore), arena.lendString(password), entries, errorMessage),
    ),
  );
  final entries = jsonDecode(utf8.decode(json));
  if (entries is! List<Object?>) {
    throw const FormatException('The key store entries are not a JSON array');
  }
  return List.unmodifiable(entries.map((entry) => KeyStoreEntry.fromJson(JsonFields.of(entry, 'A key store entry'))));
}

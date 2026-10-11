import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../bindings/ua_cryptography.g.dart';
import '../exceptions/ua_cryptography_exception.dart';
import '../pki/named_bytes.dart';
import 'native_library.dart';

/// Runs [body] with an [Arena] that releases everything lent and every buffer received when [body] returns or throws.
T callNative<T>(T Function(Arena arena) body) {
  ensureNativeLibraryVersion();
  return using(body);
}

/// Runs a C function with one output buffer and returns its bytes.
///
/// Throws the [UaCryptographyException] of a status other than OK.
Uint8List callForBytes(
  Arena arena,
  UaStatus Function(Pointer<UaBuffer> output, Pointer<UaBuffer> errorMessage) function,
) {
  final output = arena.receiveBuffer();
  final errorMessage = arena.receiveBuffer();
  throwOnRefusal(function(output, errorMessage), errorMessage);
  return copyBuffer(output);
}

/// Throws the [UaCryptographyException] of [status] with the message in [errorMessage]; returns on OK.
void throwOnRefusal(UaStatus status, Pointer<UaBuffer> errorMessage) {
  final refusal = switch (status) {
    UaStatus.UA_STATUS_OK => null,
    UaStatus.UA_STATUS_INVALID_ARGUMENT => InvalidArgumentException.new,
    UaStatus.UA_STATUS_UNREADABLE_INPUT => UnreadableInputException.new,
    UaStatus.UA_STATUS_WRONG_PASSWORD => WrongPasswordException.new,
    UaStatus.UA_STATUS_AUTHENTICATION_FAILED => AuthenticationFailedException.new,
    UaStatus.UA_STATUS_SERVICE_FAILURE => ServiceFailureException.new,
    UaStatus.UA_STATUS_INTERNAL => InternalException.new,
  };
  if (refusal != null) {
    throw refusal(utf8.decode(copyBuffer(errorMessage), allowMalformed: true));
  }
}

/// A Dart copy of the bytes of [buffer]; the buffer itself stays owned by its arena.
Uint8List copyBuffer(Pointer<UaBuffer> buffer) {
  final UaBuffer(:data, :len) = buffer.ref;
  return data == nullptr ? Uint8List(0) : Uint8List.fromList(data.asTypedList(len));
}

/// Lending inputs to and receiving outputs from the native library for the lifetime of an arena.
extension NativeArena on Arena {
  /// [bytes] copied into native memory, zeroed on release since they may be a key.
  ///
  /// Never a NULL `data`, even when empty: the C ABI reads NULL as an absent optional input.
  UaBytes lend(Uint8List bytes) {
    final data = this<Uint8>(bytes.isEmpty ? 1 : bytes.length);
    final native = data.asTypedList(bytes.length)..setAll(0, bytes);
    onReleaseAll(() => native.fillRange(0, native.length, 0));
    final lent = this<UaBytes>();
    lent.ref
      ..data = data
      ..len = bytes.length;
    return lent.ref;
  }

  /// [bytes], or an absent optional input (NULL `data`) when null.
  UaBytes lendOptional(Uint8List? bytes) {
    if (bytes != null) {
      return lend(bytes);
    }
    final absent = this<UaBytes>();
    absent.ref
      ..data = nullptr
      ..len = 0;
    return absent.ref;
  }

  /// [text] as a NUL-terminated UTF-8 string, zeroed on release since it may be a password.
  Pointer<Char> lendString(String text) {
    final encoded = utf8.encode(text);
    final data = this<Uint8>(encoded.length + 1);
    final native = data.asTypedList(encoded.length + 1)
      ..setAll(0, encoded)
      ..[encoded.length] = 0;
    onReleaseAll(() => native.fillRange(0, native.length, 0));
    return data.cast();
  }

  /// [text] as [lendString] lends it, or NULL when null.
  Pointer<Char> lendOptionalString(String? text) => text == null ? nullptr : lendString(text);

  /// Byte strings as a C array of `UaBytes`; NULL when empty, as the C ABI takes "NULL with 0".
  Pointer<UaBytes> lendByteArrays(List<Uint8List> items) {
    if (items.isEmpty) {
      return nullptr;
    }
    final array = this<UaBytes>(items.length);
    for (final (index, bytes) in items.indexed) {
      final lent = lend(bytes);
      array[index]
        ..data = lent.data
        ..len = lent.len;
    }
    return array;
  }

  /// Files as a C array of `UaNamedBytes`; NULL when empty, as the C ABI takes "NULL with 0".
  Pointer<UaNamedBytes> lendFiles(List<NamedBytes> files) {
    if (files.isEmpty) {
      return nullptr;
    }
    final array = this<UaNamedBytes>(files.length);
    for (final (index, file) in files.indexed) {
      final content = lend(file.content);
      array[index].name = lendString(file.name);
      array[index].content
        ..data = content.data
        ..len = content.len;
    }
    return array;
  }

  /// An empty buffer for the library to write, released with `ua_free_buffer` exactly once when the arena is.
  Pointer<UaBuffer> receiveBuffer() {
    final buffer = this<UaBuffer>();
    buffer.ref
      ..data = nullptr
      ..len = 0;
    onReleaseAll(() => ua_free_buffer(buffer.ref));
    return buffer;
  }
}

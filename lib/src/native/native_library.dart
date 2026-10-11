import 'package:ffi/ffi.dart';

import '../bindings/native_release.dart';
import '../bindings/ua_cryptography.g.dart';

/// Refuses a native library of another version than the bindings were generated for, once per isolate.
///
/// Throws a [StateError] naming both versions.
void ensureNativeLibraryVersion() => _loadedVersion;

// A top-level final initialises on first read; a throw leaves it unset, so a later call checks again.
final String _loadedVersion = _checkLoadedVersion();

String _checkLoadedVersion() {
  final loadedVersion = readNativeLibraryVersion();
  if (loadedVersion != nativeLibraryVersion) {
    throw StateError(
      'ua_cryptography needs the native library $nativeLibraryVersion, but $loadedVersion was loaded: '
      'the library in local_library_dir is of another release.',
    );
  }
  return loadedVersion;
}

/// The version the loaded native library reports.
String readNativeLibraryVersion() => ua_get_version().cast<Utf8>().toDartString();

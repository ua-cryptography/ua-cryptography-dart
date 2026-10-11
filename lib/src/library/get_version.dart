import '../native/native_library.dart';

/// The version of the native ua_cryptography library, e.g. `0.1.6`.
///
/// Throws a [StateError] when the loaded library is of another version than this package was built for.
String getVersion() {
  ensureNativeLibraryVersion();
  return readNativeLibraryVersion();
}

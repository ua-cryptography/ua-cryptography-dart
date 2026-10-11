/// A refusal of the native library: one subclass per status of the C ABI, carrying the library's message.
///
/// Sealed, so a `switch` over the subclasses is exhaustive. An invalid signature is not an exception: verification
/// reports it.
sealed class UaCryptographyException implements Exception {
  /// The library's explanation, in English.
  final String message;

  const UaCryptographyException(this.message);

  String get _name;

  @override
  String toString() => '$_name: $message';
}

/// An argument is of a wrong length, not UTF-8, or a name or number the library does not know.
final class InvalidArgumentException extends UaCryptographyException {
  /// Creates the exception with the library's [message].
  const InvalidArgumentException(super.message);

  @override
  String get _name => 'InvalidArgumentException';
}

/// A key store, certificate or signature does not parse.
final class UnreadableInputException extends UaCryptographyException {
  /// Creates the exception with the library's [message].
  const UnreadableInputException(super.message);

  @override
  String get _name => 'UnreadableInputException';
}

/// The key store or its key does not open with the password.
final class WrongPasswordException extends UaCryptographyException {
  /// Creates the exception with the library's [message].
  const WrongPasswordException(super.message);

  @override
  String get _name => 'WrongPasswordException';
}

/// An authenticated ciphertext or a wrapped key is not the one tagged.
final class AuthenticationFailedException extends UaCryptographyException {
  /// Creates the exception with the library's [message].
  const AuthenticationFailedException(super.message);

  @override
  String get _name => 'AuthenticationFailedException';
}

/// A time-stamping, OCSP or certificate download service failed.
final class ServiceFailureException extends UaCryptographyException {
  /// Creates the exception with the library's [message].
  const ServiceFailureException(super.message);

  @override
  String get _name => 'ServiceFailureException';
}

/// A defect of the native library: the call panicked.
final class InternalException extends UaCryptographyException {
  /// Creates the exception with the library's [message].
  const InternalException(super.message);

  @override
  String get _name => 'InternalException';
}

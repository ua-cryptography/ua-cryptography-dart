/// The outcome of one verification step.
enum CheckOutcome {
  /// The step holds.
  passed,

  /// Something could not be established; the signature itself holds.
  warning,

  /// The step fails: the signature is not valid.
  failed;

  /// Reads the `status` of a check: `passed`, `warning` or `failed`.
  static CheckOutcome fromJson(String status) => values.firstWhere(
    (outcome) => outcome.name == status,
    orElse: () => throw FormatException('Unknown check status "$status"'),
  );
}

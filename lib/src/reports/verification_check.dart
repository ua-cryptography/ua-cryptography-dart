import 'check_outcome.dart';
import 'json_fields.dart';

/// One verification step.
final class VerificationCheck {
  /// What was checked.
  final String name;

  /// How it ended.
  final CheckOutcome status;

  /// What was found.
  final String details;

  /// A step named [name] that ended with [status].
  const VerificationCheck({required this.name, required this.status, required this.details});

  /// Reads the `check_row` of a report.
  factory VerificationCheck.fromJson(Map<String, Object?> map) {
    final json = JsonFields(map);
    return VerificationCheck(
      name: json.string('name'),
      status: CheckOutcome.fromJson(json.string('status')),
      details: json.string('details'),
    );
  }
}

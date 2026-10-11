/// Typed reads of a JSON object of the native library's reports.
///
/// Throws a [FormatException] naming the field when a report does not have the shape the bindings know.
extension type const JsonFields(Map<String, Object?> json) implements Map<String, Object?> {
  /// The fields of [value], which must be a JSON object.
  static JsonFields of(Object? value, String what) => switch (value) {
    final Map<String, Object?> json => JsonFields(json),
    _ => throw FormatException('$what is not a JSON object'),
  };

  /// The field [key] as a [T].
  T read<T>(String key) => switch (json[key]) {
    final T value => value,
    final other => throw FormatException('"$key" is ${other.runtimeType}, not $T'),
  };

  /// The string field [key].
  String string(String key) => read<String>(key);

  /// The string field [key], or null.
  String? optionalString(String key) => read<String?>(key);

  /// The boolean field [key].
  bool boolean(String key) => read<bool>(key);

  /// The integer field [key].
  int integer(String key) => read<int>(key);

  /// The time field [key] (ISO 8601), in UTC.
  DateTime time(String key) => DateTime.parse(string(key)).toUtc();

  /// The time field [key] (ISO 8601) in UTC, or null.
  DateTime? optionalTime(String key) => switch (optionalString(key)) {
    final String text => DateTime.parse(text).toUtc(),
    null => null,
  };

  /// The object field [key].
  JsonFields object(String key) => of(json[key], '"$key"');

  /// The object field [key], or null.
  JsonFields? optionalObject(String key) => json[key] == null ? null : object(key);

  /// The array field [key] of strings.
  List<String> strings(String key) => List.unmodifiable(read<List<Object?>>(key).cast<String>());

  /// The array field [key] of objects, each turned into a model by [model].
  List<T> objects<T>(String key, T Function(Map<String, Object?> json) model) =>
      List.unmodifiable(read<List<Object?>>(key).map((element) => model(of(element, 'An element of "$key"'))));
}

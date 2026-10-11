/// `2026-10-10 17:30:29 UTC`.
String formatTime(DateTime time) {
  final utc = time.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${formatDay(utc)} ${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)} UTC';
}

/// `2026-10-10`.
String formatDay(DateTime time) {
  final utc = time.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)}';
}

/// `1,234 bytes`.
String formatSize(int bytes) {
  final digits = bytes.toString();
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      grouped.write(',');
    }
    grouped.write(digits[index]);
  }
  return '$grouped byte${bytes == 1 ? '' : 's'}';
}

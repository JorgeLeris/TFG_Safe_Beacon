extension DateTimeX on DateTime {
  /// Formats the date as DD/MM/YYYY.
  String toStringDate() {
    final day = this.day.toString().padLeft(2, '0');
    final month = this.month.toString().padLeft(2, '0');
    return '$day/$month/$year';
  }

  /// Formats the time as HH:MM.
  String toStringTime() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Parses a date string with format DD/MM/YYYY.
  static DateTime? tryFromStringDate(String? value) {
    if (value == null) return null;
    try {
      final parts = value.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }
}

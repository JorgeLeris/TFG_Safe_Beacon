extension DateTimeX on DateTime {
  /// Formats the date as DD/MM/YYYY.
  String toStringDate() {
    final day = this.day.toString().padLeft(2, '0');
    final month = this.month.toString().padLeft(2, '0');
    return '$day/$month/$year';
  }
}

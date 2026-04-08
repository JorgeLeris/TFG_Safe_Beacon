extension StringX on String {
  String capitalized() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

extension NullableStringX on String? {
  String orDash() => (this == null || this!.trim().isEmpty) ? '-' : this!;
}

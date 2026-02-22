extension StringX on String {
  String capitalized() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

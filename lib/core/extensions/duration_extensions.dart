extension DurationX on Duration {
  String formatDuration() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}min';
    return '$minutes min';
  }
}

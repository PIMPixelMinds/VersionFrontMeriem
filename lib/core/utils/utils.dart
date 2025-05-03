String formatDuration(String start, String? end) {
  final startTime = DateTime.parse(start).toLocal(); // <== Ici !!
  final endTime = end != null ? DateTime.parse(end).toLocal() : DateTime.now();

  final duration = endTime.difference(startTime);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours == 0 && minutes == 0) {
    return "Quelques secondes";
  } else if (hours == 0) {
    return "$minutes min";
  } else {
    return "$hours h $minutes min";
  }
}

Duration calculateDuration(String start, String? end) {
  DateTime startTime = DateTime.parse(start);
  DateTime endTime = end != null ? DateTime.parse(end) : DateTime.now();
  return endTime.difference(startTime);
}
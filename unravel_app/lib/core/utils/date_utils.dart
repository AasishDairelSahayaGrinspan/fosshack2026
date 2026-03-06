extension DateTimeUtils on DateTime {
  DateTime toDateOnly() => DateTime(year, month, day);

  int get dayIndex => toDateOnly().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

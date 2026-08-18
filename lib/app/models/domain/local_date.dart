/// 与时区无关的公历日期值，用于学习日历和连续天数计算。
final class LocalDate implements Comparable<LocalDate> {
  factory LocalDate({required int year, required int month, required int day}) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError('本地日期无效：$year-$month-$day');
    }
    return LocalDate._(year, month, day);
  }

  const LocalDate._(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime value) {
    return LocalDate(year: value.year, month: value.month, day: value.day);
  }

  final int year;
  final int month;
  final int day;

  LocalDate addDays(int days) {
    final next = DateTime.utc(year, month, day).add(Duration(days: days));
    return LocalDate._(next.year, next.month, next.day);
  }

  @override
  int compareTo(LocalDate other) {
    final yearComparison = year.compareTo(other.year);
    if (yearComparison != 0) {
      return yearComparison;
    }
    final monthComparison = month.compareTo(other.month);
    return monthComparison != 0 ? monthComparison : day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() {
    final paddedMonth = month.toString().padLeft(2, '0');
    final paddedDay = day.toString().padLeft(2, '0');
    return '$year-$paddedMonth-$paddedDay';
  }
}

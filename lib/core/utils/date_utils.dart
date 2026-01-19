class DateUtilsHelper {
  /// Devuelve la fecha formateada como "YYYY-MM-DD"
  static String formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Devuelve la fecha formateada como "YYYY-MM"
  static String formatMonth(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  /// Comprueba si dos fechas son el mismo día
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Comprueba si dos fechas son del mismo mes
  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  /// Devuelve true si la fecha está dentro del rango [start, end]
  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }
}

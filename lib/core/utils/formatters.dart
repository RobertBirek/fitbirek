import 'package:intl/intl.dart';

/// Formatery dat i liczb zgodne z polską lokalizacją.
class Formatters {
  static final _dateFormat = DateFormat('dd.MM.yyyy', 'pl_PL');
  static final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm', 'pl_PL');
  static final _timeFormat = DateFormat('HH:mm', 'pl_PL');
  static final _dayMonthFormat = DateFormat('d MMMM', 'pl_PL');
  static final _weekdayFormat = DateFormat('EEEE', 'pl_PL');

  static String date(DateTime d) => _dateFormat.format(d);
  static String dateTime(DateTime d) => _dateTimeFormat.format(d);
  static String time(DateTime d) => _timeFormat.format(d);
  static String dayMonth(DateTime d) => _dayMonthFormat.format(d);
  static String weekday(DateTime d) => _weekdayFormat.format(d);

  /// Formatuje czas trwania w sekundach jako mm:ss lub hh:mm:ss.
  static String duration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Formatuje wagę z jedną cyfrą po przecinku, np. "94.5 kg".
  static String weight(double kg) => '${kg.toStringAsFixed(1)} kg';

  /// Formatuje delte procentową ze znakiem, np. "+2.3%" lub "-1.1%".
  static String deltaPercent(double delta) {
    final sign = delta >= 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(1)}%';
  }
}

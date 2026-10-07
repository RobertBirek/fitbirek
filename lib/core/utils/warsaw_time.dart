import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

final _warsaw = (() {
  data.initializeTimeZones();
  return tz.getLocation('Europe/Warsaw');
})();
DateTime warsawTime(DateTime time) => tz.TZDateTime.from(time, _warsaw);
String warsawDayKey([DateTime? time]) {
  final d = warsawTime(time ?? DateTime.now());
  return '${d.year}-${_two(d.month)}-${_two(d.day)}';
}

String _two(int n) => n.toString().padLeft(2, '0');
String formatWarsaw(DateTime time) {
  final d = warsawTime(time);
  return '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';
}

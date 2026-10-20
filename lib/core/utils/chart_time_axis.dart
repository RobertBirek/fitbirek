/// Oś czasu w dniach od pierwszego pomiaru. Identyczne chwile mają równe X.
class ChartTimeAxis {
  ChartTimeAxis(this.origin, DateTime last)
    : maxX =
          (last.difference(origin).inMicroseconds / Duration.microsecondsPerDay)
              .clamp(1, double.infinity);
  final DateTime origin;
  final double maxX;
  double x(DateTime date) =>
      date.difference(origin).inMicroseconds / Duration.microsecondsPerDay;
  DateTime date(double x) => origin.add(
    Duration(microseconds: (x * Duration.microsecondsPerDay).round()),
  );
}

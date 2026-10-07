import '../database/app_database.dart';
import '../utils/warsaw_time.dart';

class WeightEntry {
  const WeightEntry({
    required this.date,
    required this.kg,
    this.source,
    this.sample,
  });
  final DateTime date;
  final double kg;
  final String? source;
  final HealthSampleData? sample;
  bool get imported => sample != null;
  // Compatibility with the chart's existing presentation.
  DateTime get data => imported ? warsawTime(date) : date;
  double get wagaKg => kg;
}

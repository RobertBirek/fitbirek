import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/schedule/domain/training_program.dart';
import 'package:fitbirek_training/features/schedule/domain/training_program_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import '../../core/training_sets_programs_domain_test.dart'
    show collection, programEntry, programId, planA, planB;

void main() {
  TrainingProgramSchedule schedule(List<Map<String, dynamic>> entries) =>
      TrainingProgramSchedule(TrainingPrograms.fromJson(collection(entries)));
  CalendarDay day(String date) => CalendarDay.parse(date);

  test('planned dates rotate ABA then BAB regardless of completion or window', () {
    final s = schedule([
      {...programEntry(), 'effectiveFromDate': '2026-10-19'},
    ]);
    final dates = s.between(day('2026-10-19'), day('2026-10-30'));
    expect(dates.map((o) => o.originalDate.value), [
      '2026-10-19', '2026-10-21', '2026-10-23',
      '2026-10-26', '2026-10-28', '2026-10-30',
    ]);
    expect(dates.map((o) => o.planSyncId), [planA, planB, planA, planB, planA, planB]);
    expect(s.between(day('2026-10-28'), day('2026-10-28')).single.planSyncId, planA);
    expect(dates.every((o) => o.sessionSyncId == null), isTrue);
  });

  for (final example in [
    ('2026-12-30', '2027-01-04', ['2026-12-30', '2027-01-01', '2027-01-04']),
    ('2024-02-28', '2024-03-04', ['2024-02-28', '2024-03-01', '2024-03-04']),
    ('2026-03-27', '2026-04-01', ['2026-03-27', '2026-03-30', '2026-04-01']),
    ('2026-10-23', '2026-10-28', ['2026-10-23', '2026-10-26', '2026-10-28']),
  ]) {
    test('calendar crosses ${example.$1} without local 24h arithmetic', () {
      final s = schedule([{
        ...programEntry(), 'effectiveFromDate': example.$1,
      }]);
      final items = s.between(day(example.$1), day(example.$2));
      expect(items.map((o) => o.date.value), example.$3);
      expect(items.map((o) => o.planSyncId), [planA, planB, planA]);
    });
  }

  test('midweek start and leap day use the first eligible date as A', () {
    final s = schedule([{
      ...programEntry(), 'effectiveFromDate': '2024-02-29', 'weekdays': [4, 5],
    }]);
    expect(s.between(day('2024-02-26'), day('2024-03-08')).map((o) => o.planSyncId),
        [planA, planB, planA, planB]);
    expect(s.between(day('2024-02-29'), day('2024-02-29')).single.date.value, '2024-02-29');
  });

  test('move keeps UUID and A/B; exception owns snapshot name after rename/end', () {
    final program = {...programEntry(), 'effectiveFromDate': '2026-10-19'};
    final original = schedule([program]).between(day('2026-10-21'), day('2026-10-21')).single;
    final override = <String, dynamic>{
      'id': original.id, 'kind': 'programOverride', 'name': 'Dawna nazwa',
      'createdAtUtc': '2026-10-28T00:00:00Z', 'updatedAtUtc': '2026-10-28T00:00:00Z',
      'programId': programId, 'originalDate': '2026-10-21', 'movedDate': '2027-01-01',
      'state': 'planned', 'programSnapshot': TrainingPrograms.snapshot(program),
    };
    final s = schedule([{
      ...program, 'name': 'Nowa nazwa', 'endBeforeDate': '2026-10-26',
    }, override]);
    final moved = s.between(day('2027-01-01'), day('2027-01-01')).single;
    expect(moved.id, original.id);
    expect(moved.planSyncId, planB);
    expect(moved.name, 'Dawna nazwa');
    expect(moved.programSnapshot, TrainingPrograms.snapshot(program));
    expect(s.between(day('2026-10-19'), day('2026-10-30')).map((o) => o.date.value),
        ['2026-10-19', '2026-10-23']);
  });

  test('bounded window is at most 366 inclusive calendar days', () {
    final s = schedule([programEntry()]);
    expect(() => s.between(day('2024-01-01'), day('2024-12-31')), returnsNormally);
    expect(() => s.between(day('2024-01-01'), day('2025-01-01')), throwsArgumentError);
    expect(() => s.between(day('2024-01-02'), day('2024-01-01')), throwsArgumentError);
  });
}

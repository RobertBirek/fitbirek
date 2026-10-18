import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/progress/trends/domain/training_trend.dart';

const scope = (exerciseId: 'ex', side: null, variantId: null);
TrendRow row(int session, {double? load = 20, int? reps = 8, int? rpe = 7,
  int? seconds, int set = 1, TrendScope key = scope}) => TrendRow(
  scope: key, sessionId: session, setId: session * 10 + set,
  endedAt: DateTime.utc(2026, 10, session), setNumber: set,
  exerciseName: 'Test', load: load, reps: reps, rpe: rpe, seconds: seconds,
);
void main() {
  for (var n = 0; n <= 3; n++) {
    test('$n independent sessions threshold', () {
      final report = buildTrainingTrend(scope, [for(var i=1;i<=n;i++) row(i)], tracking: 'reps');
      expect(report.series.isEmpty ? TrendStatus.tooLittleData : report.series.first.status,
        n < 2 ? TrendStatus.tooLittleData : n == 2 ? TrendStatus.comparisonOnly : TrendStatus.comparableTrend);
    });
  }
  test('loads remain separate and set counts are explicit contracts', () {
    final report = buildTrainingTrend(scope, [row(1), row(2, load: 30), row(3), row(3,set: 2)], tracking:'reps');
    expect(report.series.where((s)=>s.metric == 'Powtórzenia').length, 3);
    expect(report.series.every((s)=>s.status == TrendStatus.tooLittleData), isTrue);
  });
  for(final load in [double.nan, double.infinity, -1.0]) {
    test('invalid load $load excluded, never treated as bodyweight', () {
      final report = buildTrainingTrend(scope, [row(1,load:load)], tracking:'reps');
      expect(report.series, isEmpty);
      expect(report.exclusions.single.reason, contains('obciążenie'));
    });
  }
  test('null, both and variant UUID are independent', () {
    final report = buildTrainingTrend(scope, [row(1),row(2,key:(exerciseId:'ex',side:'both',variantId:null)),row(3,key:(exerciseId:'ex',side:null,variantId:'uuid'))], tracking:'reps');
    expect(report.observations.length,1);
  });
  test('RPE missing is not zero; different work is not lower effort', () {
    final report = buildTrainingTrend(scope,[row(1,rpe:null),row(2,rpe:6),row(3,reps:10,rpe:5)],tracking:'reps');
    final rpe = report.series.where((s)=>s.metric=='RPE').toList();
    expect(rpe.length,2);
    expect(rpe.every((s)=>s.samples.length==1),isTrue);
    expect(report.exclusions.any((e)=>e.reason.contains('RPE')),isTrue);
  });
  test('same work RPE compares separately', () {
    final report = buildTrainingTrend(scope,[row(1),row(2,rpe:6),row(3,rpe:5)],tracking:'reps');
    expect(report.series.singleWhere((s)=>s.metric=='RPE').status,TrendStatus.comparableTrend);
  });
  test('saved seconds and rounds are observations without invented protocol', () {
    for(final tracking in ['time','rounds','unknown']) {
      final report = buildTrainingTrend(scope,[row(1,reps:3,seconds:30),row(2,reps:3,seconds:30),row(3,reps:3,seconds:30)],tracking:tracking);
      expect(report.series,isEmpty);
      expect(report.observations.first.seconds,30);
      expect(report.exclusions.every((e)=>e.reason.contains('protoko')),isTrue);
    }
  });
  test('deterministic ordering and complete work signature', () {
    final report = buildTrainingTrend(scope,[row(3),row(1),row(2)],tracking:'reps');
    expect(report.series.first.samples.map((s)=>s.sessionId),[1,2,3]);
    expect(report.series.first.change,0);
  });
  test('partial invalid sets cannot silently reduce comparable set count', () {
    final report = buildTrainingTrend(scope,[row(1),row(1,set:2,reps:null),row(2)],tracking:'reps');
    expect(report.series.where((s)=>s.metric=='Powtórzenia').single.samples.length,1);
    expect(report.exclusions,isNotEmpty);
  });
  test('missing load is unknown, not proven identical work or zero kg', () {
    final report = buildTrainingTrend(scope,[row(1,load:null),row(2,load:null),row(3,load:null)],tracking:'reps');
    expect(report.series,isEmpty);
    expect(report.exclusions.every((e)=>e.reason.contains('obciążenie')),isTrue);
  });
  test('explicit finite zero is separate from unknown load', () {
    final report = buildTrainingTrend(scope,[row(1,load:0),row(2,load:0)],tracking:'reps');
    expect(report.series.first.status,TrendStatus.comparisonOnly);
  });
}

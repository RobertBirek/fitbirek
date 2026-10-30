typedef TrendScope = ({String exerciseId, String? side, String? variantId});

enum TrendStatus { tooLittleData, comparisonOnly, comparableTrend }

/// Saved execution only. No session wall clock or suggested targets enter here.
class TrendRow {
  const TrendRow({
    required this.scope,
    required this.sessionId,
    required this.setId,
    required this.endedAt,
    required this.setNumber,
    required this.exerciseName,
    this.variantLabel,
    this.load,
    this.reps,
    this.seconds,
    this.rpe,
  });
  final TrendScope scope;
  final int sessionId, setId, setNumber;
  final DateTime endedAt;
  final String exerciseName;
  final String? variantLabel;
  final double? load;
  final int? reps, seconds, rpe;
}

class TrendSample {
  const TrendSample(this.sessionId, this.date, this.value);
  final int sessionId;
  final DateTime date;
  final double value;
}

class TrendSeries {
  TrendSeries(this.metric, this.contract, this.samples);
  final String metric, contract;
  final List<TrendSample> samples;
  TrendStatus get status => samples.length < 2
      ? TrendStatus.tooLittleData
      : samples.length == 2
      ? TrendStatus.comparisonOnly
      : TrendStatus.comparableTrend;
  double? get change =>
      samples.length < 2 ? null : samples.last.value - samples.first.value;
}

class TrendExclusion {
  const TrendExclusion(this.sessionId, this.reason);
  final int sessionId;
  final String reason;
}

class TrainingTrend {
  const TrainingTrend(this.observations, this.series, this.exclusions);
  final List<TrendRow> observations;
  final List<TrendSeries> series;
  final List<TrendExclusion> exclusions;
}

TrainingTrend buildTrainingTrend(
  TrendScope scope,
  List<TrendRow> history, {
  required String tracking,
}) {
  final rows = history.where((r) => r.scope == scope).toList()
    ..sort((a, b) {
      var c = a.endedAt.compareTo(b.endedAt);
      if (c == 0) c = a.sessionId.compareTo(b.sessionId);
      if (c == 0) c = a.setNumber.compareTo(b.setNumber);
      return c == 0 ? a.setId.compareTo(b.setId) : c;
    });
  final sessions = <int, List<TrendRow>>{};
  for (final row in rows) {
    sessions.putIfAbsent(row.sessionId, () => []).add(row);
  }
  final groups = <(String, String), TrendSeries>{};
  final excluded = <TrendExclusion>[];
  void add(String metric, String contract, List<TrendRow> sets, double value) {
    groups
        .putIfAbsent((
          metric,
          contract,
        ), () => TrendSeries(metric, contract, []))
        .samples
        .add(TrendSample(sets.first.sessionId, sets.first.endedAt, value));
  }

  for (final entry in sessions.entries) {
    final sets = entry.value;
    void exclude(String reason) =>
        excluded.add(TrendExclusion(entry.key, reason));
    // The historical schema has no full interval/rest/round protocol. Even
    // equal seconds or a current catalog prescription cannot prove equality.
    if (tracking != 'reps') {
      exclude('Nieporównywalne: brak zapisanego pełnego protokołu czasu/rund.');
      continue;
    }
    if (sets.any((s) => s.load == null || !s.load!.isFinite || s.load! < 0)) {
      exclude(
        'Brak lub nieprawidłowe obciążenie; nie zakładamy 0 kg ani identycznej pracy. Wyłączono całą sesję z porównań.',
      );
      continue;
    }
    if (sets.any((s) => s.reps == null || s.reps! <= 0 || s.seconds != null)) {
      exclude(
        'Brak metryki powtórzeń lub niejednoznaczny protokół; wyłączono całą sesję.',
      );
      continue;
    }
    final loads = <double?, List<TrendRow>>{};
    for (final s in sets) {
      loads.putIfAbsent(s.load, () => []).add(s);
    }
    // Full ordered load layout prevents a 1-set fragment of a different workout
    // masquerading as an identical protocol. NULL is unknown/bodyweight, not kg 0.
    final layout = sets.map((s) => s.load?.toString() ?? 'brak kg').join(', ');
    for (final load in loads.entries) {
      final contract =
          '${sets.length} serii łącznie; układ kg [$layout]; '
          '${load.value.length} serii @ ${load.key == null ? 'bez zapisanego obciążenia' : '${load.key} kg'}';
      add(
        'Powtórzenia',
        contract,
        sets,
        load.value.fold<int>(0, (sum, s) => sum + s.reps!).toDouble(),
      );
    }
    if (sets.any((s) => s.rpe == null || s.rpe! < 1 || s.rpe! > 10)) {
      exclude('Brak pełnego rzeczywistego RPE 1–10; RPE nie jest zerem.');
    } else {
      final work = sets
          .map((s) => '${s.reps} × ${s.load ?? 'brak kg'}')
          .join('; ');
      add(
        'RPE',
        'Identyczna zapisana praca: $work; maksimum RPE serii',
        sets,
        sets.map((s) => s.rpe!).reduce((a, b) => a > b ? a : b).toDouble(),
      );
    }
  }
  return TrainingTrend(
    List.unmodifiable(rows),
    List.unmodifiable(groups.values),
    List.unmodifiable(excluded),
  );
}

enum OfflinePhase {
  unsupported,
  notReady,
  checking,
  downloading,
  ready,
  error,
  cancelled,
}

/// Resource cache only. No account data or persisted readiness flag.
class OfflineSnapshot {
  const OfflineSnapshot({
    required this.phase,
    this.packageId,
    this.totalFiles = 0,
    this.cachedFiles = 0,
    this.totalBytes = 0,
    this.cachedBytes = 0,
    this.errorCode,
  });

  final OfflinePhase phase;
  final String? packageId;
  final int totalFiles, cachedFiles, totalBytes, cachedBytes;
  final String? errorCode;

  /// A mismatch is not consent to the returned package, even with valid totals.
  bool get requiresFreshStatus => errorCode == 'packageChanged';

  /// Totals may describe another package, not this document's readiness.
  bool get requiresReload => errorCode == 'reloadRequired';
  bool get inFlight =>
      phase == OfflinePhase.checking || phase == OfflinePhase.downloading;
  bool get hasSize => packageId != null && totalFiles > 0 && totalBytes > 0;
  String get sizeLabel => '${(totalBytes / 1048576).toStringAsFixed(2)} MiB';

  factory OfflineSnapshot.parse(Object? value) {
    if (value is! Map ||
        value['protocolVersion'] != 1 ||
        value['protocolVersion'] is! int) {
      throw const FormatException('Unsupported offline protocol');
    }
    final phase = OfflinePhase.values
        .where((p) => p.name == value['state'])
        .firstOrNull;
    if (phase == null) throw const FormatException('Unknown offline state');
    for (final key in ['packageId', 'errorCode', 'message']) {
      if (!value.containsKey(key) ||
          (value[key] != null && value[key] is! String)) {
        throw const FormatException('Invalid offline metadata');
      }
    }
    int count(String key) {
      final n = value[key];
      if (n is! int || n < 0 || n > 9007199254740991) {
        throw const FormatException('Invalid offline counter');
      }
      return n;
    }

    final result = OfflineSnapshot(
      phase: phase,
      packageId: value['packageId'] as String?,
      totalFiles: count('totalFiles'),
      cachedFiles: count('cachedFiles'),
      totalBytes: count('totalBytes'),
      cachedBytes: count('cachedBytes'),
      errorCode: value['errorCode'] as String?,
    );
    if (((result.requiresFreshStatus || result.requiresReload) &&
            phase != OfflinePhase.error) ||
        result.cachedFiles > result.totalFiles ||
        result.cachedBytes > result.totalBytes ||
        (result.packageId != null && result.packageId!.trim().isEmpty) ||
        (phase == OfflinePhase.ready &&
            (!result.hasSize ||
                result.cachedFiles != result.totalFiles ||
                result.cachedBytes != result.totalBytes ||
                result.errorCode != null))) {
      throw const FormatException('Inconsistent offline snapshot');
    }
    return result;
  }
}

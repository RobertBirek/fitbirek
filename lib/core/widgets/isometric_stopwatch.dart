import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Stoper do ćwiczeń izometrycznych (plank, wall-sit, dead-hang) - liczy
/// czas w górę, zamiast w dół jak timer przerw. Zwraca liczbę sekund
/// po zatrzymaniu, żeby dało się zalogować wynik jako serię/czas.
///
/// Wywołanie: `final seconds = await showIsometricStopwatch(context, label: 'Plank');`
Future<int?> showIsometricStopwatch(
  BuildContext context, {
  required String label,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => IsometricStopwatchSheet(label: label),
  );
}

class IsometricStopwatchSheet extends StatefulWidget {
  const IsometricStopwatchSheet({super.key, required this.label});

  final String label;

  @override
  State<IsometricStopwatchSheet> createState() =>
      _IsometricStopwatchSheetState();
}

class _IsometricStopwatchSheetState extends State<IsometricStopwatchSheet> {
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _running = false;

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _finish() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(_elapsedSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Text(
              _formatted,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
                color: FitBirekColors.accent,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      _running
                          ? 'Pauza'
                          : (_elapsedSeconds == 0 ? 'Start' : 'Wznów'),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: _running ? _pause : _start,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Zakończ'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: _elapsedSeconds > 0 ? _finish : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

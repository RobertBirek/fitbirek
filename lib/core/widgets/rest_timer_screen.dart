import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';
import '../services/gong_service.dart';
import '../../features/settings/providers/settings_provider.dart';

/// Pełnoekranowy timer przerwy między seriami.
///
/// Wymagania z brief: presety 60/90/120/180s + własny czas, ogromne cyfry
/// (72sp+), pulsowanie gdy zostało <5s, gong + wibracja na koniec,
/// możliwość pominięcia przerwy.
///
/// Wywołanie: `showRestTimer(context, initialSeconds: 90)`.
Future<void> showRestTimer(BuildContext context, {int initialSeconds = 90}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) =>
          RestTimerScreen(initialSeconds: initialSeconds),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class RestTimerScreen extends ConsumerStatefulWidget {
  const RestTimerScreen({super.key, required this.initialSeconds});

  final int initialSeconds;

  @override
  ConsumerState<RestTimerScreen> createState() => _RestTimerScreenState();
}

class _RestTimerScreenState extends ConsumerState<RestTimerScreen> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialSeconds;
    _remainingSeconds = widget.initialSeconds;
    _startTicking();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _onFinished();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _onFinished() async {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 0;
      _finished = true;
    });

    final settings = ref.read(settingsProvider);
    if (settings.vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (settings.soundEnabled) {
      await GongService.playGong();
    }
  }

  void _setDuration(int seconds) {
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
      _finished = false;
    });
    _startTicking();
  }

  Future<void> _showCustomDurationDialog() async {
    final controller = TextEditingController(text: '$_totalSeconds');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Własny czas przerwy'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'sekund'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              Navigator.pop(ctx, v);
            },
            child: const Text('Ustaw'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      _setDuration(result);
    }
  }

  void _addSeconds(int delta) {
    setState(() {
      _remainingSeconds = (_remainingSeconds + delta).clamp(0, 999);
      _totalSeconds = (_totalSeconds + delta).clamp(1, 999);
      if (_remainingSeconds > 0 && _finished) {
        _finished = false;
        _startTicking();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent =
        !_finished && _remainingSeconds <= 5 && _remainingSeconds > 0;
    final progress = _totalSeconds == 0
        ? 0.0
        : _remainingSeconds / _totalSeconds;

    return Scaffold(
      backgroundColor: FitBirekColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _finished ? 'Czas minął!' : 'Przerwa',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    tooltip: 'Pomiń przerwę',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 260,
                            height: 260,
                            child: CircularProgressIndicator(
                              value: _finished ? 1 : progress,
                              strokeWidth: 10,
                              backgroundColor:
                                  FitBirekColors.darkSurfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _finished
                                    ? FitBirekColors.success
                                    : FitBirekColors.accent,
                              ),
                            ),
                          ),
                          Text(
                                _finished ? '✓' : _formatted,
                                style: TextStyle(
                                  fontSize: _finished ? 96 : 76,
                                  fontWeight: FontWeight.w800,
                                  color: isUrgent
                                      ? FitBirekColors.danger
                                      : Colors.white,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              )
                              .animate(
                                target: isUrgent ? 1 : 0,
                                onPlay: (c) => c.repeat(reverse: true),
                              )
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.15, 1.15),
                                duration: 400.ms,
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!_finished) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _adjustButton('-15s', () => _addSeconds(-15)),
                          const SizedBox(width: 16),
                          _adjustButton('+15s', () => _addSeconds(15)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        children: [
                          ...AppConstants.czasyPrzerwy.map(
                            (s) => ChoiceChip(
                              label: Text('${s}s'),
                              selected: _totalSeconds == s,
                              onSelected: (_) => _setDuration(s),
                            ),
                          ),
                          ActionChip(
                            label: const Text('Własny'),
                            onPressed: _showCustomDurationDialog,
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        'Wróć do ćwiczenia',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _finished
                        ? FitBirekColors.success
                        : FitBirekColors.darkSurfaceVariant,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    _finished ? 'Kontynuuj trening' : 'Pomiń przerwę',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adjustButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
      ),
      child: Text(label),
    );
  }
}

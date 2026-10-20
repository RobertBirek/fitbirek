import 'package:flutter/material.dart';
import '../../../../../core/widgets/content_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/utils/numeric_input.dart';
import '../../providers/measurements_providers.dart';
import '../../data/measurements_repository.dart';
import '../../../../../core/utils/formatters.dart';

/// Formularz dodania pomiaru ciała.
class AddMeasurementPage extends ConsumerStatefulWidget {
  const AddMeasurementPage({super.key, this.measurementId});
  final int? measurementId;
  @override
  ConsumerState<AddMeasurementPage> createState() => _AddMeasurementPageState();
}

class _AddMeasurementPageState extends ConsumerState<AddMeasurementPage> {
  final _waga = TextEditingController();
  final _talia = TextEditingController();
  final _klatka = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _loading = false;
  String? _error;
  MeasurementEdit? _edit;

  @override
  void initState() {
    super.initState();
    if (widget.measurementId != null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final edit = await ref
          .read(measurementsRepositoryProvider)
          .capture(widget.measurementId!);
      if (!mounted) return;
      _edit = edit;
      _waga.text = edit.row.wagaKg.toString().replaceAll('.', ',');
      _klatka.text =
          edit.row.obwodKlatki?.toString().replaceAll('.', ',') ?? '';
      _talia.text = edit.row.obwodTalii?.toString().replaceAll('.', ',') ?? '';
    } catch (error) {
      if (mounted) {
        _error = error is MeasurementSyncPending
            ? MeasurementSyncPending.message
            : 'Pomiar jest niedostępny lub konto się zmieniło. Wróć do historii pomiarów.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _waga.dispose();
    _talia.dispose();
    _klatka.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_edit != null) {
        await ref
            .read(measurementsRepositoryProvider)
            .updateMeasurement(
              _edit!,
              wagaKg: parseDecimal(_waga.text)!,
              obwodKlatki: parseDecimal(_klatka.text),
              obwodTalii: parseDecimal(_talia.text),
            );
      } else {
        await ref
            .read(measurementsRepositoryProvider)
            .addMeasurement(
              wagaKg: parseDecimal(_waga.text)!,
              obwodKlatki: parseDecimal(_klatka.text),
              obwodTalii: parseDecimal(_talia.text),
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is MeasurementSyncPending
                  ? MeasurementSyncPending.message
                  : error is MeasurementConflict
                  ? 'Pomiar lub konto się zmieniły. Wróć do historii i otwórz pomiar ponownie.'
                  : 'Nie udało się zapisać pomiaru. Spróbuj ponownie.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.measurementId == null ? 'Nowy pomiar' : 'Edytuj pomiar',
        ),
      ),
      body: ContentLayout(
        maxWidth: 640,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Padding(padding: const EdgeInsets.all(16), child: Text(_error!))
            : SafeArea(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    padding: ContentLayout.pagePadding(context),
                    children: [
                      if (_edit != null) ...[
                        Text(
                          '${Formatters.date(_edit!.row.data)} • Pomiar ręczny',
                        ),
                        const Text(
                          'Data i źródło pozostają bez zmian. Puste pole opcjonalne usuwa jego wartość.',
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _waga,
                        enabled: !_saving,
                        validator: (text) => validateMeasurement(text),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Waga (kg)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _klatka,
                        enabled: !_saving,
                        validator: (text) =>
                            validateMeasurement(text, optional: true),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Obwód klatki (cm, opcjonalnie)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _talia,
                        enabled: !_saving,
                        validator: (text) =>
                            validateMeasurement(text, optional: true),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Obwód talii (cm, opcjonalnie)',
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: _edit == null
                            ? 'Zapisz pomiar'
                            : 'Zapisz zmiany',
                        isLoading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

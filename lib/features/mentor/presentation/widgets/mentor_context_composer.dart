import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mentor_models.dart';
import '../../providers/mentor_providers.dart';

final mentorContextOptionsProvider =
    FutureProvider.autoDispose<MentorContextOptions>((ref) {
      // Options and their human previews live only for this open composer.
      return ref.watch(mentorApiProvider).contextOptions();
    });

class MentorContextComposer extends ConsumerStatefulWidget {
  const MentorContextComposer({super.key, required this.consents});

  final MentorContextConsents consents;

  @override
  ConsumerState<MentorContextComposer> createState() =>
      _MentorContextComposerState();
}

class _MentorContextComposerState extends ConsumerState<MentorContextComposer> {
  bool _training = false;
  bool _profile = false;
  bool _appleHealth = false;
  MentorContextWeightOption? _weight;
  MentorContextNoteOption? _note;
  bool _initialized = false;

  void _initialize(MentorContextOptions options) {
    if (_initialized) return;
    _initialized = true;
    _training = widget.consents.training && options.training.available;
    _profile = widget.consents.profile && options.profile.available;
    _appleHealth = widget.consents.appleHealth && options.appleHealth.available;
  }

  void _confirm(MentorContextOptions options) {
    Navigator.pop(
      context,
      MentorContextSelection(
        training: _training,
        profile: _profile,
        appleHealth: _appleHealth,
        weight: _weight,
        note: _note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(mentorContextOptionsProvider);
    return options.when(
      loading: () => const AlertDialog(
        title: Text('Kontekst tej wiadomości'),
        content: SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
      ),
      error: (_, _) => AlertDialog(
        title: const Text('Kontekst tej wiadomości'),
        content: const Text('Nie udało się pobrać kontekstu. Wiadomość nie została wysłana.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
      data: (data) {
        _initialize(data);
        return AlertDialog(
          title: const Text('Kontekst tej wiadomości'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Persona i wybrane kategorie trafiają do OpenAI tylko po zgodzie na rozmowy tekstowe.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'store:false nie gwarantuje zerowej retencji. Usunięcie rozmowy nie cofa danych wysłanych dostawcy.',
                ),
                const Divider(height: 28),
                _toggle(
                  'Kontekst treningowy',
                  widget.consents.training && data.training.available,
                  _training,
                  (value) => setState(() => _training = value),
                ),
                _toggle(
                  'Profil treningowy',
                  widget.consents.profile && data.profile.available,
                  _profile,
                  (value) => setState(() => _profile = value),
                ),
                _toggle(
                  'Apple Health',
                  widget.consents.appleHealth && data.appleHealth.available,
                  _appleHealth,
                  (value) => setState(() => _appleHealth = value),
                ),
                _selector<MentorContextWeightOption>(
                  label: 'Masa ciała',
                  enabled: widget.consents.weight && data.weights.isNotEmpty,
                  value: _weight,
                  options: data.weights,
                  labelOf: (option) => option.summary,
                  onChanged: (value) => setState(() => _weight = value),
                ),
                _selector<MentorContextNoteOption>(
                  label: 'Notatka treningowa',
                  enabled:
                      widget.consents.note && data.workoutNotes.isNotEmpty,
                  value: _note,
                  options: data.workoutNotes,
                  labelOf: (option) => '${option.summary}: ${option.preview}',
                  onChanged: (value) => setState(() => _note = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => _confirm(data),
              child: const Text('Wyślij z tym kontekstem'),
            ),
          ],
        );
      },
    );
  }

  Widget _toggle(
    String label,
    bool enabled,
    bool value,
    ValueChanged<bool> onChanged,
  ) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: value,
    onChanged: enabled ? (checked) => onChanged(checked ?? false) : null,
  );

  Widget _selector<T>({
    required String label,
    required bool enabled,
    required T? value,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    hint: Text(enabled ? 'Nie dołączaj' : 'Brak zgody lub danych'),
    items: [
      DropdownMenuItem<T>(value: null, child: const Text('Nie dołączaj')),
      ...options.map(
        (option) => DropdownMenuItem<T>(
          value: option,
          child: Text(labelOf(option), overflow: TextOverflow.ellipsis),
        ),
      ),
    ],
    onChanged: enabled ? onChanged : null,
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/utils/numeric_input.dart';
import '../../../../core/utils/profile_input.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../onboarding/providers/user_profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});
  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _wiek = TextEditingController();
  final _wzrost = TextEditingController();
  final _waga = TextEditingController();
  final _form = GlobalKey<FormState>();
  CelTreningowy _cel = CelTreningowy.mix;
  late final UserProfileRepository _repo;
  late Future<ProfileEdit> _load;
  ProfileEdit? _edit;
  bool _saving = false;

  bool _active() => mounted && (ModalRoute.of(context)?.isCurrent ?? false);

  @override
  void initState() {
    super.initState();
    _repo = ref.read(userProfileRepositoryProvider);
    _load = _capture();
  }

  Future<ProfileEdit> _capture() async {
    final edit = await _repo.captureEdit();
    if (!mounted) throw ProfileEditConflict();
    final p = edit.profile;
    _wiek.text = p.wiek.toString();
    _wzrost.text = formatProfileNumber(p.wzrostCm);
    _waga.text = formatProfileNumber(p.wagaKg);
    _cel = p.cel;
    _edit = edit;
    return edit;
  }

  @override
  void dispose() {
    _wiek.dispose();
    _wzrost.dispose();
    _waga.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _edit == null || !_form.currentState!.validate()) return;
    final edit = _edit!;
    setState(() => _saving = true);
    try {
      await _repo.saveProfile(
        edit: edit,
        isCurrent: () => _active() && identical(_edit, edit),
        imie: edit.profile.imie,
        wiek: parseProfileAge(_wiek.text)!,
        wzrostCm: parseDecimal(_wzrost.text)!,
        wagaKg: parseDecimal(_waga.text)!,
        cel: _cel,
        dostepnySprzet: edit.profile.dostepnySprzet,
        onboardingZakonczony: edit.profile.onboardingZakonczony,
      );
      await _repo.checkEditAuthority(edit);
      if (mounted && _active()) Navigator.of(context).pop();
    } catch (error) {
      if (mounted && _active()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ProfileEditConflict
                  ? 'Profil lub konto zostały zmienione. Wróć i otwórz edycję ponownie.'
                  : 'Nie udało się zapisać profilu. Spróbuj ponownie.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edytuj profil')),
    body: FutureBuilder<ProfileEdit>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() => _load = _capture()),
              child: const Text(
                'Nie można otworzyć profilu. Spróbuj ponownie.',
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _wiek,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      validator: validateProfileAge,
                      decoration: const InputDecoration(labelText: 'Wiek'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _wzrost,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => validateMeasurement(v),
                      decoration: const InputDecoration(
                        labelText: 'Wzrost (cm)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _waga,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => validateMeasurement(v),
                      decoration: const InputDecoration(labelText: 'Waga (kg)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CelTreningowy>(
                      initialValue: _cel,
                      isExpanded: true,
                      items: CelTreningowy.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _cel = v ?? _cel),
                      decoration: const InputDecoration(labelText: 'Cel'),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Zapisz',
                      isLoading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

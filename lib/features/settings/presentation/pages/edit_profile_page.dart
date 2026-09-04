import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../onboarding/providers/user_profile_provider.dart';

/// Edycja profilu użytkownika (wiek, wzrost, waga, cel).
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});
  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _wiek = TextEditingController();
  final _wzrost = TextEditingController();
  final _waga = TextEditingController();
  CelTreningowy _cel = CelTreningowy.mix;
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edytuj profil')),
      body: profileAsync.when(
        data: (p) {
          if (p != null && !_loaded) {
            _wiek.text = p.wiek.toString();
            _wzrost.text = p.wzrostCm.toStringAsFixed(0);
            _waga.text = p.wagaKg.toStringAsFixed(0);
            _cel = p.cel;
            _loaded = true;
          }
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _wiek,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Wiek'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _wzrost,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Wzrost (cm)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _waga,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Waga (kg)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CelTreningowy>(
                  initialValue: _cel,
                  items: CelTreningowy.values
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _cel = v ?? _cel),
                  decoration: const InputDecoration(labelText: 'Cel'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Zapisz',
                  onPressed: () async {
                    final repo = ref.read(userProfileRepositoryProvider);
                    await repo.saveProfile(
                      imie: p?.imie ?? 'Robert',
                      wiek: int.tryParse(_wiek.text) ?? p?.wiek ?? 47,
                      wzrostCm:
                          double.tryParse(_wzrost.text) ?? p?.wzrostCm ?? 180,
                      wagaKg: double.tryParse(_waga.text) ?? p?.wagaKg ?? 94,
                      cel: _cel,
                      dostepnySprzet:
                          p?.dostepnySprzet ?? const ['Masa własna'],
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Błąd: $e')),
      ),
    );
  }
}

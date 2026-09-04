import 'package:flutter/material.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/widgets/primary_button.dart';

/// Ekran 2 onboardingu: formularz danych osobowych.
class OnboardingProfilePage extends StatefulWidget {
  const OnboardingProfilePage({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.initialWiek,
    required this.initialWzrost,
    required this.initialWaga,
    required this.initialCel,
    required this.onDataChanged,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;
  final int initialWiek;
  final double initialWzrost;
  final double initialWaga;
  final CelTreningowy initialCel;
  final void Function(int wiek, double wzrost, double waga, CelTreningowy cel)
      onDataChanged;

  @override
  State<OnboardingProfilePage> createState() => _OnboardingProfilePageState();
}

class _OnboardingProfilePageState extends State<OnboardingProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _wiekController;
  late TextEditingController _wzrostController;
  late TextEditingController _wagaController;
  late CelTreningowy _cel;

  @override
  void initState() {
    super.initState();
    _wiekController = TextEditingController(text: widget.initialWiek.toString());
    _wzrostController =
        TextEditingController(text: widget.initialWzrost.toStringAsFixed(0));
    _wagaController =
        TextEditingController(text: widget.initialWaga.toStringAsFixed(0));
    _cel = widget.initialCel;
  }

  @override
  void dispose() {
    _wiekController.dispose();
    _wzrostController.dispose();
    _wagaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onDataChanged(
      int.parse(_wiekController.text),
      double.parse(_wzrostController.text),
      double.parse(_wagaController.text),
      _cel,
    );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Twoje dane',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Potrzebujemy tych informacji, aby dopasować kalkulacje i progres',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 28),
                _buildNumberField(
                  controller: _wiekController,
                  label: 'Wiek (lata)',
                  icon: Icons.cake_outlined,
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  controller: _wzrostController,
                  label: 'Wzrost (cm)',
                  icon: Icons.height,
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  controller: _wagaController,
                  label: 'Waga (kg)',
                  icon: Icons.monitor_weight_outlined,
                ),
                const SizedBox(height: 24),
                Text(
                  'Twój cel',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CelTreningowy>(
                  initialValue: _cel,
                  items: CelTreningowy.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _cel = v ?? _cel),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 40),
                PrimaryButton(label: 'Dalej', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'To pole jest wymagane';
        }
        final parsed = double.tryParse(value);
        if (parsed == null || parsed <= 0) {
          return 'Wpisz poprawną liczbę';
        }
        return null;
      },
    );
  }
}

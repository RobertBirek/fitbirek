import 'package:flutter/material.dart';
import '../../../health/presentation/widgets/health_integration_tile.dart';
import '../widgets/settings_section.dart';

class SettingsHealthPage extends StatelessWidget {
  const SettingsHealthPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Apple Zdrowie')),
    body: const SettingsPageLayout(
      child: SettingsSection(children: [HealthIntegrationTile()]),
    ),
  );
}

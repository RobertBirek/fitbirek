import 'package:flutter/material.dart';
import '../../../../core/models/set_role.dart';

class SetRoleSelector extends StatelessWidget {
  const SetRoleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final String value;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: const ValueKey('set-role-selector'),
    initialValue: value,
    isExpanded: true,
    isDense: false,
    itemHeight: null,
    decoration: const InputDecoration(labelText: 'Rodzaj serii'),
    items: [
      for (final role in [SetRole.working, SetRole.warmup])
        DropdownMenuItem(value: role, child: Text(SetRole.label(role))),
    ],
    onChanged: onChanged == null ? null : (value) => onChanged!(value!),
  );
}

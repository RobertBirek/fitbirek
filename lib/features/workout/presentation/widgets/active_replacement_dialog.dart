import 'package:flutter/material.dart';

class ActiveReplacementDialog extends StatefulWidget {
  const ActiveReplacementDialog({super.key, required this.description});
  final String description;
  @override
  State<ActiveReplacementDialog> createState() =>
      _ActiveReplacementDialogState();
}

class _ActiveReplacementDialogState extends State<ActiveReplacementDialog> {
  bool _discard = false;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Zamienić ćwiczenie?'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const Text(
            'Zmieniamy wyłącznie ćwiczenie. Oryginalne cele, wcześniejsze serie i historia pozostają bez zmian; nie stosujemy nowej dawki z katalogu.',
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _discard,
            onChanged: (v) => setState(() => _discard = v == true),
            title: const Text(
              'Odrzuć bieżący formularz, stronę, wariant i niezapisane wyniki timera. Inne szkice pozostaną.',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Anuluj'),
      ),
      TextButton(
        onPressed: _discard ? () => Navigator.pop(context, true) : null,
        child: const Text('Zamień'),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'content_layout.dart';

/// Lokalna droga odzyskania zadania; bez ujawniania szczegółów wyjątku.
class RecoveryMessage extends StatelessWidget {
  const RecoveryMessage({
    super.key,
    required this.message,
    required this.onRetry,
    required this.backLabel,
    required this.backLocation,
  });
  final String message, backLabel, backLocation;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ContentLayout(
    maxWidth: 640,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Spróbuj ponownie'),
          ),
          TextButton(
            onPressed: () => context.go(backLocation),
            child: Text(backLabel),
          ),
        ],
      ),
    ),
  );
}

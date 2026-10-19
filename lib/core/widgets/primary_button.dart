import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Duży przycisk - łatwy do kliknięcia jedną ręką, spoconymi palcami po serii.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = outlined
        ? theme.outlinedButtonTheme.style?.foregroundColor?.resolve({}) ??
              theme.colorScheme.primary
        : FitBirekColors.onAccent;
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      // Ładowanie blokuje akcję, ale nie wygasza wskaźnika postępu.
      backgroundColor: isLoading && !outlined
          ? const WidgetStatePropertyAll(FitBirekColors.accent)
          : null,
    );
    final child = isLoading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: foreground,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22),
                const SizedBox(width: 10),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    final button = outlined
        ? OutlinedButton(
            style: style,
            onPressed: isLoading ? null : onPressed,
            child: child,
          )
        : ElevatedButton(
            style: style,
            onPressed: isLoading ? null : onPressed,
            child: child,
          );
    if (!isLoading) return button;
    return Semantics(
      label: '$label, trwa ładowanie',
      button: true,
      enabled: false,
      liveRegion: true,
      child: ExcludeSemantics(child: button),
    );
  }
}

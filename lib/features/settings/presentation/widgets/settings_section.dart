import 'package:flutter/material.dart';

/// Shared settings canvas: bounded even on wide monitors, scrollable at large text.
class SettingsPageLayout extends StatelessWidget {
  const SettingsPageLayout({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            key: const ValueKey('settings-content'),
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width >= 760 ? 24 : 16,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: dark
                  ? const Color(0xFFB8C0CC)
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Material(
          color: dark ? const Color(0xFF23262E) : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: dark
                  ? const Color(0xFF3B414C)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: IconButtonTheme(
            data: IconButtonThemeData(
              style: (theme.iconButtonTheme.style ?? const ButtonStyle())
                  .copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                  ),
            ),
            child: ListTileTheme(
              data: ListTileThemeData(
                minVerticalPadding: 12,
                minTileHeight: 56,
                iconColor: dark
                    ? const Color(0xFFB8C0CC)
                    : theme.colorScheme.onSurfaceVariant,
                titleTextStyle: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dark
                      ? const Color(0xFFF5F6F8)
                      : theme.colorScheme.onSurface,
                ),
                subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: dark
                      ? const Color(0xFFB8C0CC)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsLink extends StatelessWidget {
  const SettingsLink({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );
}

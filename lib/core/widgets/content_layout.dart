import 'package:flutter/material.dart';

/// Ogranicza miarę treści, nie narzucając przewijania ani stanu strony.
class ContentLayout extends StatelessWidget {
  const ContentLayout({super.key, required this.child, this.maxWidth = 960});

  final Widget child;
  final double maxWidth;

  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.all(MediaQuery.sizeOf(context).width >= 1000 ? 24 : 16);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

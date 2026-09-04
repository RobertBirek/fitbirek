import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Prosty shimmer skeleton loading (zamiast spinnera) dla list.
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.08));
      },
    );
  }
}

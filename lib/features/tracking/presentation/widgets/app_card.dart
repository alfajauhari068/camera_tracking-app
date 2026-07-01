// AppCard - Reusable card component
import 'package:flutter/material.dart';
import 'package:camera_tracking_gps/core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final bool elevated;
  final Color? color;
  final VoidCallback? onTap;
  final double elevation;

  const AppCard({
    Key? key,
    required this.child,
    this.elevated = false,
    this.color,
    this.onTap,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: elevated ? 2 : elevation,
      color: color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: child,
        ),
      ),
    );
  }
}
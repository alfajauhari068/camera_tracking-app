// SectionHeader - Reusable section header component
import 'package:flutter/material.dart';
import 'package:camera_tracking_gps/core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showDivider;

  const SectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.showDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              height: 1,
            ),
          ),
      ],
    );
  }
}
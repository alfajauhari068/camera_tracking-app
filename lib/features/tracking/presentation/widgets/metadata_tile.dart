// MetadataTile - Reusable metadata display component
import 'package:flutter/material.dart';
import 'package:camera_tracking_gps/core/theme/app_theme.dart';

class MetadataTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const MetadataTile({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Divider(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              height: 1,
            ),
          ),
      ],
    );
  }
}
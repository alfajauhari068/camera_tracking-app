// StatusChip - Reusable chip/status tag component
import 'package:flutter/material.dart';
import 'package:camera_tracking_gps/core/theme/app_theme.dart';

enum StatusChipType { primary, secondary, success, warning, error, info }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipType type;
  final bool outlined;

  const StatusChip({
    Key? key,
    required this.label,
    this.type = StatusChipType.primary,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine colors based on type
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (type) {
      case StatusChipType.primary:
        backgroundColor = theme.colorScheme.secondary.withOpacity(0.2);
        foregroundColor = theme.colorScheme.secondary;
        borderColor = theme.colorScheme.secondary;
        break;
      case StatusChipType.secondary:
        backgroundColor = theme.colorScheme.surfaceVariant.withOpacity(0.3);
        foregroundColor = theme.colorScheme.onSurfaceVariant;
        borderColor = theme.colorScheme.onSurfaceVariant;
        break;
      case StatusChipType.success:
        backgroundColor = theme.colorScheme.tertiary.withOpacity(0.2);
        foregroundColor = theme.colorScheme.tertiary;
        borderColor = theme.colorScheme.tertiary;
        break;
      case StatusChipType.warning:
        backgroundColor = theme.colorScheme.error.withOpacity(0.2);
        foregroundColor = theme.colorScheme.error;
        borderColor = theme.colorScheme.error;
        break;
      case StatusChipType.error:
        backgroundColor = theme.colorScheme.error.withOpacity(0.2);
        foregroundColor = theme.colorScheme.error;
        borderColor = theme.colorScheme.error;
        break;
      case StatusChipType.info:
        backgroundColor = theme.colorScheme.primary.withOpacity(0.2);
        foregroundColor = theme.colorScheme.primary;
        borderColor = theme.colorScheme.primary;
        break;
    }

    if (outlined) {
      backgroundColor = Colors.transparent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: outlined
            ? Border.all(
                color: borderColor,
                width: 1,
              )
            : null,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
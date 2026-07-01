// AppButton - Reusable button component
import 'package:flutter/material.dart';
import 'package:camera_tracking_gps/core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final double? width;
  final double? height;

  const AppButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine button style based on variant
    ButtonStyle style;
    switch (variant) {
      case AppButtonVariant.primary:
        style = ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPadding,
            vertical: AppSpacing.buttonPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        );
        break;
      case AppButtonVariant.secondary:
        style = ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceVariant,
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPadding,
            vertical: AppSpacing.buttonPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        );
        break;
      case AppButtonVariant.outline:
        style = OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.secondary,
          side: BorderSide(
            color: theme.colorScheme.secondary,
            width: 2,
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPadding,
            vertical: AppSpacing.buttonPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        );
        break;
    }

    final Widget child;
    if (isLoading) {
      child = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? Colors.black : Colors.white,
          ),
        ),
      );
    } else {
      child = Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: variant == AppButtonVariant.outline
          ? OutlinedButton(
              style: style,
              onPressed: onPressed,
              child: child,
            )
          : ElevatedButton(
              style: style,
              onPressed: onPressed,
              child: child,
            ),
    );
  }
}
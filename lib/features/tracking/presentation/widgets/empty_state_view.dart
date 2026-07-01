// EmptyStateView - Reusable empty state component
import 'package:flutter/material.dart';
import 'package:camera_tracking_gps/core/theme/app_theme.dart';
import 'app_button.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateView({
    Key? key,
    required this.title,
    this.message,
    this.icon = Icons.inbox,
    this.buttonText,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  message!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (buttonText != null && onButtonPressed != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: AppButton(
                  label: buttonText!,
                  onPressed: onButtonPressed!,
                  variant: AppButtonVariant.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
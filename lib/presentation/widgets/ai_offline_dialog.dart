import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AiOfflineDialog extends StatelessWidget {
  final VoidCallback onUseOfflineAi;
  final VoidCallback onCancel;

  const AiOfflineDialog({
    super.key,
    required this.onUseOfflineAi,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Offline Mode'),
      content: const Text(
          'You are currently offline. Basic AI features are available, but advanced transcription requires an internet connection. Do you want to continue with limited functionality?'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onUseOfflineAi,
          child: const Text('Continue Offline'),
        ),
      ],
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    );
  }
}

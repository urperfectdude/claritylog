import 'package:flutter/material.dart';

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
      title: const Text('You are offline'),
      content: const Text(
        'AI transcription requires an internet connection. Would you like to save without transcription or try again later?',
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onUseOfflineAi,
          child: const Text('Save w/o AI'),
        ),
      ],
    );
  }
}

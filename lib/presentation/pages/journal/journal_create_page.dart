import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../services/audio_service.dart';
import '../../providers/journal/journal_provider.dart';
import '../../widgets/common/stat_card.dart';

class JournalCreatePage extends ConsumerStatefulWidget {
  const JournalCreatePage({super.key});

  @override
  ConsumerState<JournalCreatePage> createState() => _JournalCreatePageState();
}

class _JournalCreatePageState extends ConsumerState<JournalCreatePage> {
  final _contentController = TextEditingController();
  bool _isRecording = false;
  bool _isSaving = false;
  bool _isTranscribing = false;
  String? _recordedAudioPath;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void dispose() {
    _contentController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await AudioService.instance.startRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });

        // Max 5 minutes recording
        if (_recordingSeconds >= 300) {
          _stopRecording();
        }
      });

      // Haptic feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final path = await AudioService.instance.stopRecording();

    setState(() {
      _isRecording = false;
      _recordedAudioPath = path;
    });

    HapticFeedback.mediumImpact();

    if (path != null) {
      await _transcribeAudio(path);
    }
  }

  Future<void> _transcribeAudio(String path) async {
    final isOnline = await NetworkUtils.isOnline;

    if (!isOnline) {
      // Show offline AI dialog
      final useOffline = await showDialog<bool>(
        context: context,
        builder: (context) => AiOfflineDialog(
          onUseOfflineAi: () => Navigator.pop(context, true),
          onCancel: () => Navigator.pop(context, false),
        ),
      );

      if (useOffline != true) {
        return;
      }
    }

    setState(() {
      _isTranscribing = true;
    });

    try {
      // TODO: Call Whisper API via Edge Function
      // For now, simulate transcription
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _contentController.text = 'Voice transcription will appear here after connecting to OpenAI Whisper API.';
        _isTranscribing = false;
      });
    } catch (e) {
      setState(() {
        _isTranscribing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transcription failed: $e')),
      );
    }
  }

  Future<void> _saveJournal() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(journalListProvider.notifier).createJournal(
            content: content,
            audioUrl: _recordedAudioPath,
            isVoice: _recordedAudioPath != null,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal saved!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('New Journal'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveJournal,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.secondary,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Content input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind today?',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),

          // Recording status
          if (_isRecording || _isTranscribing)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              color: AppTheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRecording) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      'Recording ${_formatDuration(_recordingSeconds)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (_isTranscribing) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      'Transcribing...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),

          // Bottom toolbar
          Container(
            padding: EdgeInsets.only(
              left: AppTheme.spacingLg,
              right: AppTheme.spacingLg,
              bottom: MediaQuery.of(context).padding.bottom + AppTheme.spacingMd,
              top: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(color: AppTheme.divider),
              ),
            ),
            child: Row(
              children: [
                // Mood selector (placeholder)
                IconButton(
                  onPressed: () {
                    // TODO: Show mood selector
                  },
                  icon: const Text('😊', style: TextStyle(fontSize: 24)),
                ),

                const Spacer(),

                // Voice recording button (tap and hold)
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isRecording ? 80 : 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isRecording ? AppTheme.error : AppTheme.secondary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: AppTheme.error.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                ),

                const Spacer(),

                // Gallery picker (placeholder)
                IconButton(
                  onPressed: () {
                    // TODO: Add image attachment
                  },
                  icon: Icon(
                    Icons.image_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/app_utils.dart';

/// Service for audio recording (voice journals)
class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();

  AudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Check if recording is available
  Future<bool> checkPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording audio
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentRecordingPath = '${directory.path}/journal_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentRecordingPath!,
    );

    _isRecording = true;
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;

    return path;
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    await _recorder.stop();
    _isRecording = false;

    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _currentRecordingPath = null;
  }

  /// Get recording amplitude stream for visualization
  Stream<Amplitude> get amplitudeStream => _recorder.onAmplitudeChanged(
        const Duration(milliseconds: 100),
      );

  /// Dispose recorder
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

/// Service for managing audio file uploads
class AudioUploadService {
  static final _supabase = SupabaseConfig.client;

  /// Upload audio file to Supabase storage
  static Future<String?> uploadAudio({
    required String filePath,
    required String userId,
    required String journalId,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final storagePath = '$userId/$journalId.m4a';

      await _supabase.storage
          .from('audio-recordings')
          .uploadBinary(storagePath, bytes,
              fileOptions: const FileOptions(
                contentType: 'audio/m4a',
                upsert: true,
              ));

      // Return the storage path for later retrieval
      return storagePath;
    } catch (e) {
      return null;
    }
  }

  /// Get signed URL for audio playback
  static Future<String?> getAudioUrl(String path) async {
    try {
      final url = await _supabase.storage
          .from('audio-recordings')
          .createSignedUrl(path, 3600); // 1 hour expiry
      return url;
    } catch (e) {
      return null;
    }
  }

  /// Delete audio file from storage
  static Future<void> deleteAudio(String path) async {
    try {
      await _supabase.storage.from('audio-recordings').remove([path]);
    } catch (e) {
      // Log error
    }
  }
}

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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
      final fileName = 'journals/$userId/$journalId.m4a';

      // This would upload to Supabase Storage
      // For now, return the expected URL format
      // Actual implementation requires SupabaseConfig.client.storage

      return fileName;
    } catch (e) {
      return null;
    }
  }

  /// Get signed URL for audio playback
  static Future<String?> getAudioUrl(String path) async {
    try {
      // This would get signed URL from Supabase Storage
      // Actual implementation requires SupabaseConfig.client.storage
      return path;
    } catch (e) {
      return null;
    }
  }

  /// Delete audio file from storage
  static Future<void> deleteAudio(String path) async {
    try {
      // This would delete from Supabase Storage
      // Actual implementation requires SupabaseConfig.client.storage
    } catch (e) {
      // Log error
    }
  }
}

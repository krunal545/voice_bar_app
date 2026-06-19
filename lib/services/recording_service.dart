import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingService {
  RecordingService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  String? _currentPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    if (_isRecording) return;

    final hasMic = await hasPermission();
    if (!hasMic) {
      throw RecordingException('Microphone permission denied');
    }

    final dir = await getApplicationSupportDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = Platform.isWindows ? 'wav' : 'm4a';
    _currentPath = '${recordingsDir.path}/recording_$timestamp.$extension';

    await _recorder.start(
      RecordConfig(
        encoder: Platform.isWindows ? AudioEncoder.wav : AudioEncoder.aacLc,
      ),
      path: _currentPath!,
    );
    _isRecording = true;
  }

  Future<String?> stop() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;
    return path ?? _currentPath;
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }
    await _recorder.dispose();
  }
}

class RecordingException implements Exception {
  RecordingException(this.message);
  final String message;

  @override
  String toString() => message;
}

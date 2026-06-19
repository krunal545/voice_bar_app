import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'paste_service.dart';
import 'recording_service.dart';
import 'transcription_service.dart';

enum VoiceBarStatus { idle, recording, transcribing, pasting, error }

class VoiceController extends ChangeNotifier {
  VoiceController({
    RecordingService? recordingService,
  }) : _recordingService = recordingService ?? RecordingService();

  final RecordingService _recordingService;
  static const _lifecycleChannel = MethodChannel('com.voicebar/lifecycle');

  VoiceBarStatus _status = VoiceBarStatus.idle;
  String? _lastRecordingPath;
  String? _lastTranscription;
  String? _errorMessage;
  bool _hasAccessibility = false;
  Timer? _accessibilityPollTimer;

  VoiceBarStatus get status => _status;
  String? get lastRecordingPath => _lastRecordingPath;
  String? get lastTranscription => _lastTranscription;
  String? get errorMessage => _errorMessage;
  bool get isRecording => _status == VoiceBarStatus.recording;
  bool get hasAccessibility => _hasAccessibility;

  Future<void> initialize() async {
    _lifecycleChannel.setMethodCallHandler((call) async {
      if (call.method == 'appBecameActive') {
        await refreshAccessibility();
      }
    });

    await PasteService.requestAccessibility();
    await TranscriptionService.requestPermission();
    await refreshAccessibility();
    _syncAccessibilityPolling();
  }

  Future<void> refreshAccessibility() async {
    _hasAccessibility = await PasteService.hasAccessibility();

    if (_hasAccessibility) {
      if (_status == VoiceBarStatus.error) {
        _status = VoiceBarStatus.idle;
        _errorMessage = null;
      }
      _stopAccessibilityPolling();
    } else if (_status != VoiceBarStatus.recording &&
        _status != VoiceBarStatus.transcribing &&
        _status != VoiceBarStatus.pasting) {
      _status = VoiceBarStatus.error;
      _errorMessage = Platform.isWindows
          ? 'Microphone access is required. Check Windows privacy settings.'
          : 'Enable Accessibility for Voice Bar in System Settings, then return here.';
      _startAccessibilityPolling();
    }

    notifyListeners();
  }

  Future<void> openAccessibilitySettings() async {
    await PasteService.requestAccessibility();
    await PasteService.openAccessibilitySettings();
    _startAccessibilityPolling();
  }

  Future<void> toggleRecording() async {
    if (_status == VoiceBarStatus.transcribing || _status == VoiceBarStatus.pasting) {
      return;
    }

    if (_status == VoiceBarStatus.recording) {
      await _stopRecordingAndPaste();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!_hasAccessibility) {
      await PasteService.requestAccessibility();
      await refreshAccessibility();
      if (!_hasAccessibility) {
        _status = VoiceBarStatus.error;
        _errorMessage = Platform.isWindows
            ? 'Microphone access is required. Check Windows privacy settings.'
            : 'Enable Accessibility for Voice Bar in System Settings, then return here.';
        notifyListeners();
        return;
      }
    }

    final hasSpeech = await TranscriptionService.hasPermission();
    if (!hasSpeech) {
      await TranscriptionService.requestPermission();
      if (!await TranscriptionService.hasPermission()) {
        _status = VoiceBarStatus.error;
        _errorMessage =
            Platform.isWindows
            ? 'Enable microphone access for Voice Bar in Windows Settings.'
            : 'Enable Speech Recognition for Voice Bar in System Settings.';
        notifyListeners();
        return;
      }
    }

    _errorMessage = null;
    _lastTranscription = null;

    try {
      await _recordingService.start();
      _status = VoiceBarStatus.recording;
      notifyListeners();
    } catch (e) {
      _status = VoiceBarStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _stopRecordingAndPaste() async {
    _status = VoiceBarStatus.transcribing;
    notifyListeners();

    try {
      _lastRecordingPath = await _recordingService.stop();
      final recordingPath = _lastRecordingPath;

      if (recordingPath == null || recordingPath.isEmpty) {
        throw RecordingException('Recording file was not created');
      }

      final transcription = await TranscriptionService.transcribeFile(recordingPath);
      _lastTranscription = transcription;

      _status = VoiceBarStatus.pasting;
      notifyListeners();

      await PasteService.captureTargetApp();

      final pasted = await PasteService.pasteTextAtCursor(transcription);

      if (!pasted) {
        await refreshAccessibility();
        _status = VoiceBarStatus.error;
        _errorMessage = _hasAccessibility
            ? 'Paste failed. Click a text field, then try F5 again.'
            : Platform.isWindows
            ? 'Paste failed. Click a text field, then try F5 again.'
            : 'Enable Accessibility for Voice Bar, then try again.';
      } else {
        _status = VoiceBarStatus.idle;
        _errorMessage = null;
      }
    } on TranscriptionException catch (e) {
      _status = VoiceBarStatus.error;
      _errorMessage = e.message;
    } on PlatformException catch (e) {
      _status = VoiceBarStatus.error;
      _errorMessage = e.message ?? 'Speech recognition failed';
    } catch (e) {
      _status = VoiceBarStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  void _syncAccessibilityPolling() {
    if (_hasAccessibility) {
      _stopAccessibilityPolling();
    } else {
      _startAccessibilityPolling();
    }
  }

  void _startAccessibilityPolling() {
    _accessibilityPollTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => refreshAccessibility(),
    );
  }

  void _stopAccessibilityPolling() {
    _accessibilityPollTimer?.cancel();
    _accessibilityPollTimer = null;
  }

  @override
  void dispose() {
    _stopAccessibilityPolling();
    _recordingService.dispose();
    super.dispose();
  }
}

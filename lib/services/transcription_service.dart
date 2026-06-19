import 'package:flutter/services.dart';

class TranscriptionService {
  static const _channel = MethodChannel('com.voicebar/speech');

  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasSpeechPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestSpeechPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<String> transcribeFile(String path) async {
    try {
      final result = await _channel.invokeMethod<String>('transcribeAudioFile', path);
      final text = result?.trim() ?? '';
      if (text.isEmpty) {
        throw TranscriptionException('No speech detected. Try speaking louder.');
      }
      return text;
    } on PlatformException catch (e) {
      throw TranscriptionException(e.message ?? 'Speech recognition failed');
    }
  }
}

class TranscriptionException implements Exception {
  TranscriptionException(this.message);

  final String message;

  @override
  String toString() => message;
}

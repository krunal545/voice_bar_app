import 'package:flutter/services.dart';

class PasteService {
  static const _channel = MethodChannel('com.voicebar/paste');

  static Future<bool> hasAccessibility() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasAccessibility');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> requestAccessibility() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestAccessibility');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> captureTargetApp() async {
    try {
      await _channel.invokeMethod<void>('captureTargetApp');
    } on PlatformException {
      // Ignore — paste will target the current frontmost app.
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod<void>('openAccessibilitySettings');
    } on PlatformException {
      // Ignore.
    }
  }

  /// Saves clipboard, writes [text], sends Cmd+V, then restores clipboard.
  static Future<bool> pasteTextAtCursor(String text) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'pasteTextAtCursor',
        text,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}

import Foundation
import FlutterMacOS
import Speech

enum SpeechHelper {
  static func hasPermission() -> Bool {
    SFSpeechRecognizer.authorizationStatus() == .authorized
  }

  static func requestPermission(completion: @escaping (Bool) -> Void) {
    SFSpeechRecognizer.requestAuthorization { status in
      DispatchQueue.main.async {
        completion(status == .authorized)
      }
    }
  }

  static func transcribeAudioFile(
    path: String,
    completion: @escaping (String?, FlutterError?) -> Void
  ) {
    let status = SFSpeechRecognizer.authorizationStatus()
    guard status == .authorized else {
      completion(
        nil,
        FlutterError(
          code: "SPEECH_PERMISSION_DENIED",
          message: "Speech recognition permission denied",
          details: nil
        )
      )
      return
    }

    guard let recognizer = SFSpeechRecognizer(locale: Locale.current) else {
      completion(
        nil,
        FlutterError(
          code: "SPEECH_UNAVAILABLE",
          message: "Speech recognizer is not available for the current language",
          details: nil
        )
      )
      return
    }

    guard recognizer.isAvailable else {
      completion(
        nil,
        FlutterError(
          code: "SPEECH_UNAVAILABLE",
          message: "Speech recognition is not available right now",
          details: nil
        )
      )
      return
    }

    guard FileManager.default.fileExists(atPath: path) else {
      completion(
        nil,
        FlutterError(
          code: "FILE_NOT_FOUND",
          message: "Recording file not found",
          details: path
        )
      )
      return
    }

    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: path))
    request.shouldReportPartialResults = false

    var finished = false
    recognizer.recognitionTask(with: request) { result, error in
      if finished {
        return
      }

      if let error = error {
        finished = true
        completion(
          nil,
          FlutterError(
            code: "TRANSCRIPTION_FAILED",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }

      guard let result = result, result.isFinal else {
        return
      }

      finished = true
      let text = result.bestTranscription.formattedString
        .trimmingCharacters(in: .whitespacesAndNewlines)

      if text.isEmpty {
        completion(
          nil,
          FlutterError(
            code: "NO_SPEECH",
            message: "No speech detected. Try speaking louder and closer to the mic.",
            details: nil
          )
        )
      } else {
        completion(text, nil)
      }
    }
  }
}

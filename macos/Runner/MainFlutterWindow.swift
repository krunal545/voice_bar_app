import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let pasteChannel = FlutterMethodChannel(
      name: "com.voicebar/paste",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    let speechChannel = FlutterMethodChannel(
      name: "com.voicebar/speech",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    speechChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "hasSpeechPermission":
        result(SpeechHelper.hasPermission())
      case "requestSpeechPermission":
        SpeechHelper.requestPermission { granted in
          result(granted)
        }
      case "transcribeAudioFile":
        guard let path = call.arguments as? String else {
          result(
            FlutterError(
              code: "INVALID_ARGS",
              message: "Audio file path is required",
              details: nil
            )
          )
          return
        }
        SpeechHelper.transcribeAudioFile(path: path) { text, error in
          if let error = error {
            result(error)
          } else {
            result(text)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    AppDelegate.onAppBecameActive = { [weak flutterViewController] in
      guard let messenger = flutterViewController?.engine.binaryMessenger else { return }
      FlutterMethodChannel(name: "com.voicebar/lifecycle", binaryMessenger: messenger)
        .invokeMethod("appBecameActive", arguments: nil)
    }

    pasteChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "pasteTextAtCursor":
        guard let text = call.arguments as? String else {
          result(
            FlutterError(
              code: "INVALID_ARGS",
              message: "Text argument is required",
              details: nil
            )
          )
          return
        }
        result(PasteHelper.pasteTextAtCursor(text: text))
      case "hasAccessibility":
        result(PasteHelper.hasAccessibilityPermission())
      case "requestAccessibility":
        result(PasteHelper.requestAccessibilityPermission())
      case "captureTargetApp":
        PasteHelper.captureTargetApp()
        result(true)
      case "openAccessibilitySettings":
        PasteHelper.openAccessibilitySettings()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}

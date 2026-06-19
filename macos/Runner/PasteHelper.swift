import AppKit
import ApplicationServices
import FlutterMacOS

enum PasteHelper {
  private static var targetApp: NSRunningApplication?

  static func hasAccessibilityPermission() -> Bool {
    AXIsProcessTrusted()
  }

  @discardableResult
  static func requestAccessibilityPermission() -> Bool {
    let options =
      [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
  }

  static func captureTargetApp() {
    guard let front = NSWorkspace.shared.frontmostApplication else { return }

    let ownBundleId = Bundle.main.bundleIdentifier
    if front.bundleIdentifier == ownBundleId {
      return
    }

    targetApp = front
  }

  static func openAccessibilitySettings() {
    let urls = [
      "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
      "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
    ]
    for urlString in urls {
      if let url = URL(string: urlString), NSWorkspace.shared.open(url) {
        return
      }
    }
  }

  static func pasteTextAtCursor(text: String) -> Bool {
    guard hasAccessibilityPermission() else {
      return false
    }

    let pasteboard = NSPasteboard.general
    let savedItems = saveClipboard(pasteboard)

    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)

    activateTargetApp()
    Thread.sleep(forTimeInterval: 0.12)

    guard postCommandV() else {
      restoreClipboard(pasteboard: pasteboard, savedItems: savedItems)
      return false
    }

    Thread.sleep(forTimeInterval: 0.12)
    restoreClipboard(pasteboard: pasteboard, savedItems: savedItems)
    return true
  }

  private static func activateTargetApp() {
    guard let app = targetApp, !app.isTerminated else { return }
    app.activate(options: [.activateIgnoringOtherApps])
  }

  private static func postCommandV() -> Bool {
    let source = CGEventSource(stateID: .hidSystemState)
    let vKeyCode: CGKeyCode = 9

    guard
      let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
      let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
    else {
      return false
    }

    keyDown.flags = .maskCommand
    keyUp.flags = .maskCommand
    keyDown.post(tap: .cghidEventTap)
    keyUp.post(tap: .cghidEventTap)
    return true
  }

  private static func saveClipboard(_ pasteboard: NSPasteboard) -> [[String: Data]] {
    pasteboard.pasteboardItems?.map { item in
      var dict: [String: Data] = [:]
      for type in item.types {
        if let data = item.data(forType: type) {
          dict[type.rawValue] = data
        }
      }
      return dict
    } ?? []
  }

  private static func restoreClipboard(
    pasteboard: NSPasteboard,
    savedItems: [[String: Data]]
  ) {
    pasteboard.clearContents()
    guard !savedItems.isEmpty else { return }

    let items = savedItems.map { dict -> NSPasteboardItem in
      let item = NSPasteboardItem()
      for (type, data) in dict {
        item.setData(data, forType: NSPasteboard.PasteboardType(type))
      }
      return item
    }
    pasteboard.writeObjects(items)
  }
}

import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  static var onAppBecameActive: (() -> Void)?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidBecomeActive(_ notification: Notification) {
    super.applicationDidBecomeActive(notification)
    AppDelegate.onAppBecameActive?()
  }
}

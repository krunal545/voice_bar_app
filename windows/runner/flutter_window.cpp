#include "flutter_window.h"

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "paste_helper.h"
#include "speech_helper.h"

namespace {

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return "";
  }

  const int size = WideCharToMultiByte(CP_UTF8, 0, value.c_str(), -1, nullptr, 0,
                                       nullptr, nullptr);
  if (size <= 0) {
    return "";
  }

  std::string utf8(size - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.c_str(), -1, utf8.data(), size, nullptr,
                      nullptr);
  return utf8;
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return L"";
  }

  const int size =
      MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, nullptr, 0);
  if (size <= 0) {
    return L"";
  }

  std::wstring wide(size - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, wide.data(), size);
  return wide;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  paste_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "com.voicebar/paste",
      &flutter::StandardMethodCodec::GetInstance());
  paste_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const auto& method = call.method_name();
        if (method == "pasteTextAtCursor") {
          const auto* text = std::get_if<std::string>(call.arguments());
          if (!text) {
            result->Error("INVALID_ARGS", "Text argument is required");
            return;
          }
          result->Success(flutter::EncodableValue(
              PasteHelper::PasteTextAtCursor(Utf8ToWide(*text))));
        } else if (method == "hasAccessibility") {
          result->Success(flutter::EncodableValue(
              PasteHelper::HasAccessibilityPermission()));
        } else if (method == "requestAccessibility") {
          result->Success(flutter::EncodableValue(
              PasteHelper::RequestAccessibilityPermission()));
        } else if (method == "captureTargetApp") {
          PasteHelper::CaptureTargetApp();
          result->Success(flutter::EncodableValue(true));
        } else if (method == "openAccessibilitySettings") {
          PasteHelper::OpenAccessibilitySettings();
          result->Success(flutter::EncodableValue(true));
        } else {
          result->NotImplemented();
        }
      });

  speech_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "com.voicebar/speech",
      &flutter::StandardMethodCodec::GetInstance());
  speech_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const auto& method = call.method_name();
        if (method == "hasSpeechPermission") {
          result->Success(flutter::EncodableValue(SpeechHelper::HasPermission()));
        } else if (method == "requestSpeechPermission") {
          result->Success(flutter::EncodableValue(SpeechHelper::RequestPermission()));
        } else if (method == "transcribeAudioFile") {
          const auto* path = std::get_if<std::string>(call.arguments());
          if (!path) {
            result->Error("INVALID_ARGS", "Audio file path is required");
            return;
          }

          std::wstring error;
          const std::wstring transcription =
              SpeechHelper::TranscribeAudioFile(Utf8ToWide(*path), &error);
          if (!error.empty()) {
            result->Error("TRANSCRIPTION_FAILED", WideToUtf8(error));
            return;
          }

          result->Success(flutter::EncodableValue(WideToUtf8(transcription)));
        } else {
          result->NotImplemented();
        }
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  paste_channel_.reset();
  speech_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

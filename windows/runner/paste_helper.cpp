#include "paste_helper.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>

#include <memory>
#include <string>
#include <thread>
#include <vector>

namespace {

HWND g_target_window = nullptr;
DWORD g_target_thread_id = 0;

struct ClipboardSnapshot {
  UINT format = 0;
  std::vector<BYTE> data;
};

std::vector<ClipboardSnapshot> SaveClipboard() {
  std::vector<ClipboardSnapshot> saved;
  if (!OpenClipboard(nullptr)) {
    return saved;
  }

  const UINT format = EnumClipboardFormats(0);
  for (UINT current = format; current != 0;
       current = EnumClipboardFormats(current)) {
    HANDLE handle = GetClipboardData(current);
    if (!handle) {
      continue;
    }

    const SIZE_T size = GlobalSize(handle);
    if (size == 0) {
      continue;
    }

    const void* locked = GlobalLock(handle);
    if (!locked) {
      continue;
    }

    ClipboardSnapshot snapshot;
    snapshot.format = current;
    snapshot.data.resize(size);
    memcpy(snapshot.data.data(), locked, size);
    GlobalUnlock(handle);
    saved.push_back(std::move(snapshot));
  }

  CloseClipboard();
  return saved;
}

void RestoreClipboard(const std::vector<ClipboardSnapshot>& saved) {
  if (!OpenClipboard(nullptr)) {
    return;
  }

  EmptyClipboard();
  for (const auto& snapshot : saved) {
    HGLOBAL handle = GlobalAlloc(GMEM_MOVEABLE, snapshot.data.size());
    if (!handle) {
      continue;
    }

    void* locked = GlobalLock(handle);
    if (!locked) {
      GlobalFree(handle);
      continue;
    }

    memcpy(locked, snapshot.data.data(), snapshot.data.size());
    GlobalUnlock(handle);
    SetClipboardData(snapshot.format, handle);
  }

  CloseClipboard();
}

bool SetClipboardText(const std::wstring& text) {
  if (!OpenClipboard(nullptr)) {
    return false;
  }

  EmptyClipboard();

  const SIZE_T byte_count = (text.size() + 1) * sizeof(wchar_t);
  HGLOBAL handle = GlobalAlloc(GMEM_MOVEABLE, byte_count);
  if (!handle) {
    CloseClipboard();
    return false;
  }

  void* locked = GlobalLock(handle);
  if (!locked) {
    GlobalFree(handle);
    CloseClipboard();
    return false;
  }

  memcpy(locked, text.c_str(), byte_count);
  GlobalUnlock(handle);

  const bool success = SetClipboardData(CF_UNICODETEXT, handle) != nullptr;
  CloseClipboard();
  return success;
}

bool PostCtrlV() {
  INPUT inputs[4] = {};

  inputs[0].type = INPUT_KEYBOARD;
  inputs[0].ki.wVk = VK_CONTROL;

  inputs[1].type = INPUT_KEYBOARD;
  inputs[1].ki.wVk = 'V';

  inputs[2].type = INPUT_KEYBOARD;
  inputs[2].ki.wVk = 'V';
  inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;

  inputs[3].type = INPUT_KEYBOARD;
  inputs[3].ki.wVk = VK_CONTROL;
  inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;

  return SendInput(4, inputs, sizeof(INPUT)) == 4;
}

void ActivateTargetWindow() {
  if (!g_target_window || !IsWindow(g_target_window)) {
    return;
  }

  if (IsIconic(g_target_window)) {
    ShowWindow(g_target_window, SW_RESTORE);
  }

  AllowSetForegroundWindow(g_target_thread_id);
  SetForegroundWindow(g_target_window);
}

}  // namespace

namespace PasteHelper {

bool HasAccessibilityPermission() {
  return true;
}

bool RequestAccessibilityPermission() {
  return true;
}

void CaptureTargetApp() {
  HWND foreground = GetForegroundWindow();
  if (!foreground) {
    return;
  }

  DWORD process_id = 0;
  GetWindowThreadProcessId(foreground, &process_id);
  if (process_id == GetCurrentProcessId()) {
    return;
  }

  g_target_window = foreground;
  g_target_thread_id = GetWindowThreadProcessId(foreground, nullptr);
}

void OpenAccessibilitySettings() {
  ShellExecuteW(nullptr, L"open", L"ms-settings:privacy-microphone", nullptr,
              nullptr, SW_SHOWNORMAL);
}

bool PasteTextAtCursor(const std::wstring& text) {
  if (text.empty()) {
    return false;
  }

  const auto saved = SaveClipboard();
  if (!SetClipboardText(text)) {
    RestoreClipboard(saved);
    return false;
  }

  ActivateTargetWindow();
  std::this_thread::sleep_for(std::chrono::milliseconds(120));

  if (!PostCtrlV()) {
    RestoreClipboard(saved);
    return false;
  }

  std::this_thread::sleep_for(std::chrono::milliseconds(120));
  RestoreClipboard(saved);
  return true;
}

}  // namespace PasteHelper

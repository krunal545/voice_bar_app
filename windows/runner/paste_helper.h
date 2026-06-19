#ifndef RUNNER_PASTE_HELPER_H_
#define RUNNER_PASTE_HELPER_H_

#include <string>
#include <vector>

namespace PasteHelper {

bool HasAccessibilityPermission();
bool RequestAccessibilityPermission();
void CaptureTargetApp();
void OpenAccessibilitySettings();
bool PasteTextAtCursor(const std::wstring& text);

}  // namespace PasteHelper

#endif  // RUNNER_PASTE_HELPER_H_

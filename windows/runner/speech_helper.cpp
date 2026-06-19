#include "speech_helper.h"

#include <filesystem>
#include <string>

namespace SpeechHelper {

bool HasPermission() {
  return true;
}

bool RequestPermission() {
  return true;
}

std::wstring TranscribeAudioFile(const std::wstring& path,
                                 std::wstring* error) {
  if (!std::filesystem::exists(path)) {
    if (error) {
      *error = L"Recording file not found";
    }
    return L"";
  }

  if (error) {
    *error =
        L"Speech transcription is unavailable in this test build. Recording and paste UI still work.";
  }
  return L"";
}

}  // namespace SpeechHelper

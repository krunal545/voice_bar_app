#ifndef RUNNER_SPEECH_HELPER_H_
#define RUNNER_SPEECH_HELPER_H_

#include <string>

namespace SpeechHelper {

bool HasPermission();
bool RequestPermission();
std::wstring TranscribeAudioFile(const std::wstring& path, std::wstring* error);

}  // namespace SpeechHelper

#endif  // RUNNER_SPEECH_HELPER_H_

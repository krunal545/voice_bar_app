#include "speech_helper.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <sapi.h>

#pragma warning(push)
#pragma warning(disable : 4996)
#include <sphelper.h>
#pragma warning(pop)

#include <filesystem>
#include <string>

#pragma comment(lib, "sapi.lib")

namespace {

std::wstring Trim(const std::wstring& value) {
  const auto start = value.find_first_not_of(L" \t\r\n");
  if (start == std::wstring::npos) {
    return L"";
  }

  const auto end = value.find_last_not_of(L" \t\r\n");
  return value.substr(start, end - start + 1);
}

template <typename T>
void Release(T*& pointer) {
  if (pointer) {
    pointer->Release();
    pointer = nullptr;
  }
}

}  // namespace

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

  HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  const bool should_uninitialize = SUCCEEDED(hr);

  ISpRecognizer* recognizer = nullptr;
  hr = CoCreateInstance(CLSID_SpInprocRecognizer, nullptr, CLSCTX_ALL,
                        IID_ISpRecognizer, reinterpret_cast<void**>(&recognizer));
  if (FAILED(hr) || !recognizer) {
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"Speech recognizer is not available on this PC";
    }
    return L"";
  }

  ISpRecoContext* context = nullptr;
  hr = recognizer->CreateRecoContext(&context);
  if (FAILED(hr) || !context) {
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"Failed to create speech recognition context";
    }
    return L"";
  }

  HANDLE event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
  if (!event) {
    Release(context);
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"Failed to initialize speech recognition";
    }
    return L"";
  }

  hr = context->SetNotifyWin32Event(event, nullptr, 0, 0, 0);
  if (FAILED(hr)) {
    CloseHandle(event);
    Release(context);
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"Failed to configure speech recognition";
    }
    return L"";
  }

  hr = context->SetInterest(SPFEI(SPEI_RECOGNITION), SPFEI(SPEI_RECOGNITION));
  if (FAILED(hr)) {
    CloseHandle(event);
    Release(context);
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"Failed to configure speech recognition";
    }
    return L"";
  }

  ISpRecoGrammar* grammar = nullptr;
  hr = context->CreateGrammar(0, &grammar);
  if (FAILED(hr) || !grammar) {
    CloseHandle(event);
    Release(context);
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"Failed to create speech grammar";
    }
    return L"";
  }

  hr = grammar->LoadDictation(nullptr, SPLO_STATIC);
  if (FAILED(hr)) {
    CloseHandle(event);
    Release(grammar);
    Release(context);
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"Failed to load dictation grammar";
    }
    return L"";
  }

  hr = grammar->SetDictationState(SPRS_ACTIVE);
  if (FAILED(hr)) {
    CloseHandle(event);
    Release(grammar);
    Release(context);
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"Failed to activate dictation";
    }
    return L"";
  }

  ISpStream* stream = nullptr;
  hr = SPBindToFile(path.c_str(), SPFM_OPEN_READONLY, &stream);
  if (FAILED(hr) || !stream) {
    CloseHandle(event);
    Release(grammar);
    Release(context);
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error =
          L"Could not read the recording. On Windows, recordings are saved as WAV.";
    }
    return L"";
  }

  hr = recognizer->SetInput(stream, TRUE);
  if (FAILED(hr)) {
    CloseHandle(event);
    Release(stream);
    Release(grammar);
    Release(context);
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"Failed to open audio for transcription";
    }
    return L"";
  }

  const DWORD wait_result = WaitForSingleObject(event, 30000);
  if (wait_result != WAIT_OBJECT_0) {
    CloseHandle(event);
    Release(stream);
    Release(grammar);
    Release(context);
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"No speech detected. Try speaking louder and closer to the mic.";
    }
    return L"";
  }

  ISpRecoResult* result = nullptr;
  hr = context->GetResult(0, &result);
  if (FAILED(hr) || !result) {
    CloseHandle(event);
    Release(stream);
    Release(grammar);
    Release(context);
    Release(recognizer);
    if (should_uninitialize) {
      CoUninitialize();
    }
    if (error) {
      *error = L"No speech detected. Try speaking louder and closer to the mic.";
    }
    return L"";
  }

  LPWSTR text = nullptr;
  hr = result->GetText(static_cast<ULONG>(SP_GETWHOLEPHRASE),
                       static_cast<ULONG>(SP_GETWHOLEPHRASE), TRUE, &text,
                       nullptr);
  std::wstring transcription;
  if (SUCCEEDED(hr) && text) {
    transcription = Trim(text);
    CoTaskMemFree(text);
  }

  grammar->SetDictationState(SPRS_INACTIVE);
  CloseHandle(event);
  Release(result);
  Release(stream);
  Release(grammar);
  Release(context);
  Release(recognizer);
  if (should_uninitialize) {
    CoUninitialize();
  }

  if (transcription.empty()) {
    if (error) {
      *error = L"No speech detected. Try speaking louder and closer to the mic.";
    }
    return L"";
  }

  return transcription;
}

}  // namespace SpeechHelper

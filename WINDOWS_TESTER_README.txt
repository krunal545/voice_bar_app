Voice Bar - Windows Testing Guide
=================================

OPTION A - Easiest (if you receive a pre-built zip)
---------------------------------------------------
1. Unzip voice_bar_app-windows.zip
2. Double-click voice_bar_app.exe
3. Allow microphone access when Windows asks
4. Click a text field in any app (Notepad, Word, browser, etc.)
5. Press F5 to start recording, press F5 again to stop and paste text

OPTION B - Build from source (if you only have the project zip)
---------------------------------------------------------------
Requirements:
- Windows 10 or 11 (64-bit)
- Flutter SDK: https://docs.flutter.dev/get-started/install/windows
- Visual Studio 2022 with "Desktop development with C++"

Steps:
1. Unzip this project folder
2. Double-click BUILD_FOR_TESTERS.bat
3. When build finishes, run:
   build\windows\x64\runner\Release\voice_bar_app.exe

How to test
-----------
- The voice bar appears as a small bar near the bottom of the screen
- F5 = start recording
- F5 again = stop, transcribe, and paste at cursor
- Click into another app first so paste goes to the right place

Troubleshooting
---------------
- No speech detected: speak closer to the mic, check Windows speech language pack
- Paste failed: click a text field first, then try F5 again
- Mic denied: Settings > Privacy > Microphone > allow for this app

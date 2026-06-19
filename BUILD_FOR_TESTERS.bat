@echo off
setlocal enabledelayedexpansion

echo ============================================
echo   Voice Bar - Windows Test Build
echo ============================================
echo.

where flutter >nul 2>&1
if errorlevel 1 (
  echo Flutter is not installed or not on PATH.
  echo.
  echo Install Flutter first:
  echo   https://docs.flutter.dev/get-started/install/windows
  echo.
  echo Also install "Desktop development with C++" in Visual Studio Build Tools.
  echo.
  pause
  exit /b 1
)

echo [1/3] Getting dependencies...
call flutter pub get
if errorlevel 1 goto :failed

echo.
echo [2/3] Building Windows release...
call flutter build windows --release
if errorlevel 1 goto :failed

set "APP_DIR=build\windows\x64\runner\Release"
set "EXE=%APP_DIR%\voice_bar_app.exe"

if not exist "%EXE%" (
  echo Build finished but exe was not found at:
  echo   %EXE%
  goto :failed
)

echo.
echo [3/3] Build complete!
echo.
echo Executable: %CD%\%EXE%
echo.
echo IMPORTANT: Share or run the entire Release folder, not only the .exe.
echo The app needs the DLL files and data folder next to the exe.
echo.
set /p RUN="Launch Voice Bar now? (Y/N): "
if /I "%RUN%"=="Y" start "" "%EXE%"

echo.
echo Done. Send the whole "%APP_DIR%" folder to other testers.
pause
exit /b 0

:failed
echo.
echo Build failed. Check the errors above.
pause
exit /b 1

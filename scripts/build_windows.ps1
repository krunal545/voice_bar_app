# Builds a release Windows executable for local testing.
# Run this script on a Windows PC with Flutter and Visual Studio installed.

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "Building Voice Bar for Windows (release)..." -ForegroundColor Cyan
flutter pub get
flutter build windows --release

$exePath = Join-Path $projectRoot "build\windows\x64\runner\Release\voice_bar_app.exe"
if (-not (Test-Path $exePath)) {
  throw "Build finished but executable was not found at $exePath"
}

$distDir = Join-Path $projectRoot "dist\windows"
if (Test-Path $distDir) {
  Remove-Item $distDir -Recurse -Force
}
New-Item -ItemType Directory -Path $distDir | Out-Null

$releaseDir = Join-Path $projectRoot "build\windows\x64\runner\Release"
Copy-Item -Path (Join-Path $releaseDir "*") -Destination $distDir -Recurse -Force

$zipPath = Join-Path $projectRoot "dist\voice_bar_app-windows.zip"
if (Test-Path $zipPath) {
  Remove-Item $zipPath -Force
}
Compress-Archive -Path (Join-Path $distDir "*") -DestinationPath $zipPath -Force

Write-Host ""
Write-Host "Build complete." -ForegroundColor Green
Write-Host "Executable: $exePath"
Write-Host "Portable folder: $distDir"
Write-Host "Zip package: $zipPath"
Write-Host ""
Write-Host "Copy the entire Release folder (or unzip the package) to your Windows test machine."

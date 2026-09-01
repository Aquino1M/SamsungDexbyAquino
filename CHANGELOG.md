# Changelog

## 0.2.0-enhanced — 2026-09-01

Public Enhanced foundation by Aquino.

### Added
- ADB supervisor with retry and controlled recovery.
- Authorization wait before APK/JAR dependent initialization.
- Reverse-port repair for TCP 3698–3702.
- Borderless fullscreen helper for Android Dex and scrcpy windows.
- Wireless ADB pair/connect/disconnect helper.
- Health diagnostics with privacy-safe device identifiers.
- Game profile configuration foundation.
- Manufacturer compatibility database foundation.
- Aquino Control Center launcher.
- GitHub CI validation for PowerShell/JSON.
- Bug and feature request templates.
- Roadmap for 20 compatibility/gaming improvements.
- Aquino authorship, copyright and source-available license.

### Known limitation
- The provided archive contains a compiled Flutter Windows build, not the original Flutter source tree. Deep UI changes and direct integration into the existing Flutter interface require the original `lib/`, `windows/`, `android/` and `pubspec.yaml` sources.

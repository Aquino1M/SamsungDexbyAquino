# Changelog

## 0.3.4 — UI V1.3 / Guia sem vídeos

- Atualizada a versão exibida no rodapé para **V.1.3**.
- Removida a área de vídeos do **Guia de Conexão Android**.
- O antigo painel de vídeos agora abre diretamente o conteúdo manual PT-BR.
- `Patch-CompiledUi.ps1` ganhou parâmetro `-UiVersion` e validação do patch binário antes da alteração.
- Mantido backup restaurável do `app.so` original.

## 0.3.0 — Gaming Engine

- Added **Aquino Gaming Hub** and one-click `start_gaming_hub.bat`.
- Added independent Android app/game windows using bundled scrcpy 4.0 virtual displays.
- Added flex display, fullscreen, ultrawide and per-game profiles.
- Added native UHID keyboard, relative mouse and SDL3/UHID gamepad launching.
- Added visual **Aquino KeyMapper** with normalized coordinates and saved per-package JSON profiles.
- Added keyboard/mouse runtime with tap, repeated tap, swipe, D-pad, scripts and FPS-look fallback.
- Added XInput-to-touch mappings for touchscreen-only games.
- Added automatic device encoder probing and codec selection.
- Added 90/144/165 FPS profiles and low-latency scrcpy buffers.
- Added scrcpy diagnostics/probe tool.
- Updated Control Center with a Gaming Hub entry point.

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

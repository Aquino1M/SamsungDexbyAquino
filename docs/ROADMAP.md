# Roadmap — Android Dex by Aquino

Legend: ✅ implemented · 🟡 implemented with device/game limitations · ⬜ future/native bridge

1. ✅ **Borderless/fullscreen gaming** — Android_Dex and scrcpy fullscreen.
2. ✅ **Fullscreen/per-app profiles** — package can be opened with a selected gaming profile.
3. ✅ **Adaptive aspect ratio** — scrcpy 4 flex display resizes the Android virtual display with the PC window.
4. ✅ **Ultrawide 21:9 / 32:9** — virtual display presets.
5. 🟡 **Android 16 compatibility** — uses scrcpy 4 virtual/flex display; manufacturer-specific Android 16 limitations remain possible.
6. ✅ **Manufacturer compatibility database**.
7. ✅ **Per-app keymap/profile format**.
8. ✅ **Game Profiles 2.0** — resolution, DPI, FPS, codec, bitrate, latency, fullscreen and UHID settings.
9. ✅ **Gamepad support** — native SDL3/UHID through scrcpy; XInput-to-touch fallback in Aquino KeyMapper.
10. ✅ **Visual keymapping editor** — capture the scrcpy window and click to place controls.
11. ✅ **FPS mouse lock** — native UHID relative mouse for supported games; F1 touch-look fallback for touchscreen-only titles.
12. ✅ **30/60/90/120/144/165 FPS targets** — actual FPS depends on game/device/display.
13. ✅ **Automatic codec probing** — prefers AV1, H.265, H.264, VP9 or VP8 from device encoder list.
14. ✅ **Low-latency gaming profile** — zero video buffer and reduced audio buffers where supported.
15. ✅ **Robust ADB recovery**.
16. ✅ **Modern Wireless ADB**.
17. 🟡 **USB ↔ Wi-Fi fallback** — connection tools exist; live in-game migration may still restart a scrcpy session.
18. ✅ **Independent Android app windows** — scrcpy `--new-display` + `--start-app` + flex display.
19. 🟡 **Session persistence** — profiles/keymaps persist; automatic reopening of every previous window is planned.
20. ✅ **Health/diagnostic center**.

## Aquino Gaming Engine v0.3

The gaming layer no longer depends on the original Flutter UI for most gaming features. It runs beside the compiled Android Dex build and uses the bundled scrcpy 4.0/ADB. Touchscreen keymapping is implemented as an external compatibility fallback; native UHID keyboard/mouse/gamepad should be preferred whenever a game accepts physical controls.

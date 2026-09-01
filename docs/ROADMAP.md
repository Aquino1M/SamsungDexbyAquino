# Roadmap — Android Dex by Aquino

Legend: ✅ implemented in Enhanced layer · 🟡 foundation/partial · ⬜ requires original application source or deeper integration

1. ✅ **Borderless fullscreen for games** — fullscreen helper for Android_Dex/scrcpy windows.
2. 🟡 **Fullscreen rules per application** — profile schema ready; automatic package-to-window integration requires app source.
3. 🟡 **Adaptive aspect ratio** — profile schema supports resolution/aspect presets.
4. 🟡 **Ultrawide 21:9 / 32:9 profiles** — presets included; virtual-display integration pending.
5. 🟡 **Android 16 compatibility layer** — compatibility data and non-invasive launcher checks added; application-side display changes pending.
6. ✅ **Manufacturer compatibility database** — Samsung, Xiaomi/Redmi/POCO, Motorola, Pixel, OnePlus, OPPO, realme, vivo, Nothing.
7. 🟡 **Per-app compatibility profiles** — JSON override format added.
8. 🟡 **Game Profiles 2.0** — persistent profile format added with FPS/codec/latency/fullscreen/resolution fields.
9. ⬜ **Native XInput / DualSense / DirectInput support** — requires input pipeline source.
10. ⬜ **Visual keymapping editor** — requires UI/input source.
11. 🟡 **FPS mouse lock** — fullscreen/process foundation ready; raw relative mouse input requires source integration.
12. 🟡 **30/60/90/120/144/165 FPS presets** — profile values added; backend enforcement pending.
13. 🟡 **Automatic codec choice** — profile model includes auto/H.264/H.265/AV1 preference; encoder capability probing pending.
14. 🟡 **Low-latency gaming mode** — low-latency profile added; backend buffer tuning pending.
15. ✅ **Robust ADB recovery** — daemon restart, authorization wait and retry implemented.
16. ✅ **Modern Wireless ADB helper** — pair/connect/disconnect/status implemented.
17. 🟡 **Automatic USB ↔ Wi-Fi fallback** — wireless helper exists; seamless live transport migration pending.
18. 🟡 **Desktop window manager behavior** — fullscreen/window controls added externally; per-app native windows require source.
19. 🟡 **Desktop session persistence** — profile/runtime format foundation; automatic window restore pending.
20. ✅ **Health/diagnostic center** — executable, ADB, devices, companion APK, JARs, FFmpeg, WebView2 and reverse-port checks.

## Next source-level milestone

When the original Flutter project is available, priority order:

1. integrate Health Center into the Flutter UI;
2. add App Compatibility Service keyed by Android package name;
3. integrate fullscreen/profile actions into the app launcher;
4. add display presets and Android 16 adaptive/resizable behavior;
5. implement native gamepad + raw mouse input;
6. add visual keymapping editor;
7. implement automatic encoder/FPS capability probing;
8. add session restoration and USB/Wi-Fi seamless failover.

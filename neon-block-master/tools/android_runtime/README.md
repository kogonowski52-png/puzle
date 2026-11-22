# Android WebView readiness bridge

Build with `python3 tools/build_android_runtime.py` after installing the pinned Godot Android template. The bridge AAR is needed in both debug and release exports; Godot is compile-only and is not bundled again. `tools/build_cloud.sh` builds this module before exporting.

`NeonWebView` exposes `prepare()` and a JSON `webview_ready` signal. The plain Android helper runs local JavaScript on the UI thread in a network-blocked temporary view and releases it. It never loads or simulates an ad and never grants a reward. The GDScript adapter applies the existing child-directed request configuration before starting AdMob after success.

Tests: `./android/build/gradlew -p tools/android_diagnostics/tests testDebugUnitTest`. The test project extracts the exact Godot API jar from the installed template. Robolectric callback probes validate lifecycle and settings; they do not establish hardware WebView execution or actual ad serving. See `docs/WEBVIEW-1.4.1.md`.

Debug-only `read_ads_log()` / `ads_log_ready` captures selected SDK tags from the current process after a JavascriptEngine failure. It is limited to 160 lines / 16 KiB / 1.5 seconds, runs off the UI thread, needs no READ_LOGS permission and performs no network transmission. Release calls are rejected by the native debuggable flag check.

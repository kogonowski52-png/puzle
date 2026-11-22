# Local Android crash reporting (debug builds only)

The crash shown on the owner's Samsung S25 FE persists in 1.3.1. No further root cause has been confirmed. This diagnostic APK is **not a verified fix**.

`StartupActivity` runs in a separate `:diagnostics` process before launching the unchanged Godot activity. It can show the main process's previous Android exit reason and, on supported Android versions, its native tombstone. `CrashApplication` records uncaught Java failures before delegating to Android's original handler. A Java-only historical exit without a saved stack launches the game once to collect the actual failure.

Reports stay in internal app storage. Sharing is initiated by the owner; nothing is sent automatically. The non-exported report provider accepts read-only access to two fixed file names using temporary URI grants. Scores and game progress are not deleted or included in reports. Native traces may contain technical app/device details; inspect reports before sharing them publicly.

Build from a prepared Godot 4.6.3/JDK/SDK environment:

```sh
source tools/cloud_env.sh
python3 tools/build_diagnostic_apk.py
```

This creates version code 6, `1.3.2-diagnostic`, with the existing debug certificate and Google test ad units. Temporary presets and the diagnostic project setting are restored afterward. Normal builds do not enable the launcher/reporting components, and release AABs do not include the diagnostic AAR.

After installation, open the app. If it exits, open it again. Use **Kopiuj raport** or **Udostępnij plik raportu** to provide the actual error. A native crash can include `neon-native-trace.pb`, which is needed for native backtrace analysis. Do not infer a Java or graphics root cause from Samsung's generic clear-cache dialog.

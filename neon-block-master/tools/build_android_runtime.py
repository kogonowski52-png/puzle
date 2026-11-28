"""Compatibility entry point for rebuilding the complete Android ad runtime."""
from pathlib import Path
import os,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
def main():
    sdk=Path(os.environ['ANDROID_HOME'])
    godot=ROOT/'android/build/libs/debug/godot-lib.template_debug.aar'
    explicit=os.environ.get('NEON_UMP_AAR')
    cache=Path(os.environ.get('GRADLE_USER_HOME',str(Path.home()/'.gradle')))
    candidates=[Path(explicit)] if explicit else list((cache/'caches/modules-2/files-2.1/com.google.android.ump/user-messaging-platform/4.0.0').glob('*/*.aar'))
    if not candidates or not candidates[0].is_file():
        raise SystemExit('Set NEON_UMP_AAR to the official user-messaging-platform-4.0.0.aar or use tools/build_ad_runtime.py with explicit paths. A compiled runtime is included in the repository.')
    subprocess.run([sys.executable,str(ROOT/'tools/build_ad_runtime.py'),'--android-jar',str(sdk/'platforms/android-36/android.jar'),'--godot-aar',str(godot),'--ump-aar',str(candidates[0])],check=True)
if __name__=='__main__':main()

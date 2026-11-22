"""Build a separate local-reporting debug APK; restore normal project settings afterward."""
from pathlib import Path
import argparse, subprocess, sys, re
ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'builds/neon-block-master-diagnostic.apk')
    args=parser.parse_args()
    subprocess.run([sys.executable,str(ROOT/'tools/build_android_runtime.py')],check=True)
    subprocess.run([sys.executable,str(ROOT/'tools/build_diagnostics.py')],check=True)
    preset=ROOT/'export_presets.cfg';project=ROOT/'project.godot'
    original=preset.read_text();original_project=project.read_text()
    first=original[:original.index('[preset.1]')]
    extra=first.replace('[preset.0','[preset.4').replace('name="Android APK"','name="Android Diagnostic"')
    extra=re.sub(r'version/code=(\d+)',lambda match:'version/code='+str(int(match[1])+1),extra)
    extra=re.sub(r'version/name="([^"]+)"',lambda match:'version/name="'+match[1]+'-diagnostic"',extra)
    try:
        preset.write_text(original+'\n'+extra)
        project.write_text(original_project if '[neon]' in original_project else original_project+'\n[neon]\ndebug_startup_report=true\n')
        args.output.resolve().parent.mkdir(parents=True,exist_ok=True)
        subprocess.run(['godot','--headless','--path',str(ROOT),'--export-debug','Android Diagnostic',str(args.output.resolve())],check=True)
    finally:
        preset.write_text(original);project.write_text(original_project)

if __name__=='__main__':main()

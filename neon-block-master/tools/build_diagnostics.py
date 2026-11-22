"""Build the local-only Android debug crash reporter. Requires JDK and Android SDK."""
from pathlib import Path
import os, subprocess, tempfile, zipfile
ROOT=Path(__file__).resolve().parents[1]

def main():
    sdk=Path(os.environ['ANDROID_HOME'])
    javac=Path(os.environ['JAVA_HOME'])/'bin/javac'
    sources=sorted((ROOT/'tools/android_diagnostics/src').rglob('*.java'))
    destination=ROOT/'addons/neon_ads/diagnostics/startup-diagnostics-debug.aar'
    destination.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory() as temp:
        classes=Path(temp)/'classes';classes.mkdir()
        subprocess.run([str(javac),'--release','8','-cp',str(sdk/'platforms/android-36/android.jar'),'-d',str(classes),*[str(p) for p in sources]],check=True)
        jar=Path(temp)/'classes.jar'
        with zipfile.ZipFile(jar,'w',zipfile.ZIP_DEFLATED) as output:
            for path in sorted(classes.rglob('*.class')):output.write(path,str(path.relative_to(classes)))
        with zipfile.ZipFile(destination,'w',zipfile.ZIP_DEFLATED) as output:
            output.write(jar,'classes.jar')
            output.writestr('AndroidManifest.xml','<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.neonblockmaster.diagnostics"><uses-sdk android:minSdkVersion="24"/><application/></manifest>')
            output.writestr('R.txt','')
    print('Built local-only debug crash reporter:',destination)

if __name__=='__main__':main()

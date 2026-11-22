"""Build the Android WebView readiness bridge against the pinned Godot API."""
from pathlib import Path
import os,subprocess,tempfile,zipfile
ROOT=Path(__file__).resolve().parents[1]
def main():
    sdk=Path(os.environ['ANDROID_HOME']);javac=Path(os.environ['JAVA_HOME'])/'bin/javac'
    godot=ROOT/'android/build/libs/debug/godot-lib.template_debug.aar'
    sources=sorted((ROOT/'tools/android_runtime/src').rglob('*.java'))
    output=ROOT/'addons/neon_ads/runtime/neon-webview.aar';output.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory() as temp:
        temp=Path(temp);classes=temp/'classes';classes.mkdir()
        api=temp/'godot.jar'
        with zipfile.ZipFile(godot) as z:api.write_bytes(z.read('classes.jar'))
        classpath=os.pathsep.join([str(sdk/'platforms/android-36/android.jar'),str(api)])
        subprocess.run([str(javac),'--release','8','-cp',classpath,'-d',str(classes),*[str(p) for p in sources]],check=True)
        jar=temp/'classes.jar'
        with zipfile.ZipFile(jar,'w',zipfile.ZIP_DEFLATED) as z:
            for p in classes.rglob('*.class'):z.write(p,str(p.relative_to(classes)))
        with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
            z.write(jar,'classes.jar');z.writestr('R.txt','')
            z.writestr('AndroidManifest.xml','<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.neonblockmaster.android"><uses-sdk android:minSdkVersion="24"/><application><meta-data android:name="org.godotengine.plugin.v2.NeonWebView" android:value="com.neonblockmaster.android.NeonWebView"/></application></manifest>')
    print('Built Android WebView bridge:',output)
if __name__=='__main__':main()

"""Rebuild the Android WebView/log/UMP bridge with the pinned official APIs."""
from pathlib import Path
import argparse,os,subprocess,tempfile,zipfile
ROOT=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--android-jar',type=Path,required=True)
    parser.add_argument('--godot-aar',type=Path,required=True)
    parser.add_argument('--ump-aar',type=Path,required=True)
    args=parser.parse_args()
    output=ROOT/'addons/neon_ads/runtime/neon-webview.aar'
    with tempfile.TemporaryDirectory() as temp:
        temp=Path(temp);jars=[]
        for name,path in [('godot',args.godot_aar),('ump',args.ump_aar)]:
            jar=temp/(name+'.jar')
            with zipfile.ZipFile(path) as z:jar.write_bytes(z.read('classes.jar'))
            jars.append(jar)
        classes=temp/'classes';classes.mkdir()
        compiler=temp/'Compile.java'
        compiler.write_text('class Compile {public static void main(String[] args) {System.exit(javax.tools.ToolProvider.getSystemJavaCompiler().run(null,System.out,System.err,args));}}')
        sources=sorted((ROOT/'tools/android_runtime/src').rglob('*.java'))
        subprocess.run(['java',str(compiler),'-source','8','-target','8','-cp',os.pathsep.join(map(str,[args.android_jar,*jars])),'-d',str(classes),*map(str,sources)],check=True)
        jar=temp/'classes.jar'
        with zipfile.ZipFile(jar,'w',zipfile.ZIP_DEFLATED) as z:
            for path in classes.rglob('*.class'):z.write(path,str(path.relative_to(classes)))
        with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
            z.write(jar,'classes.jar');z.writestr('R.txt','')
            z.writestr('AndroidManifest.xml','<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.neonblockmaster.android"><uses-sdk android:minSdkVersion="24"/><application><meta-data android:name="org.godotengine.plugin.v2.NeonWebView" android:value="com.neonblockmaster.android.NeonWebView"/><meta-data android:name="org.godotengine.plugin.v2.NeonConsent" android:value="com.neonblockmaster.android.NeonConsent"/></application></manifest>')
    print('Built Android ad runtime:',output)
if __name__=='__main__':main()

"""Compile the purchase bridge against real Android/Godot/Play Billing APIs."""
from pathlib import Path
import argparse
import os
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--android-jar', type=Path, required=True)
    parser.add_argument('--godot-aar', type=Path, required=True)
    parser.add_argument('--billing-aar', type=Path, required=True)
    args = parser.parse_args()
    output = ROOT/'addons/neon_billing/runtime/neon-billing.aar'
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temp:
        temp = Path(temp)
        jars = []
        for label, aar in [('godot', args.godot_aar), ('billing', args.billing_aar)]:
            jar = temp/(label+'.jar')
            with zipfile.ZipFile(aar) as z:
                jar.write_bytes(z.read('classes.jar'))
            jars.append(jar)
        classes = temp/'classes'
        classes.mkdir()
        sources = sorted((ROOT/'tools/android_billing/src').rglob('*.java'))
        options = ['-source','8','-target','8','-cp',os.pathsep.join(map(str,[args.android_jar,*jars])), '-d',str(classes),*map(str,sources)]
        # Single-file source launch also works on a JDK exposing jdk.compiler
        # without a separate javac executable (as in the managed Cloud runtime).
        compiler = temp/'Compile.java'
        compiler.write_text('class Compile { public static void main(String[] args) { System.exit(javax.tools.ToolProvider.getSystemJavaCompiler().run(null, System.out, System.err, args)); } }')
        subprocess.run(['java',str(compiler),*options],check=True)
        jar = temp/'classes.jar'
        with zipfile.ZipFile(jar,'w',zipfile.ZIP_DEFLATED) as z:
            for path in sorted(classes.rglob('*.class')):
                z.write(path,str(path.relative_to(classes)))
        with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
            z.write(jar,'classes.jar')
            z.writestr('R.txt','')
            z.writestr('AndroidManifest.xml','<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.neonblockmaster.billing"><uses-sdk android:minSdkVersion="24"/><uses-permission android:name="com.android.vending.BILLING"/><application><meta-data android:name="org.godotengine.plugin.v2.NeonBilling" android:value="com.neonblockmaster.billing.NeonBilling"/></application></manifest>')
    print('Built:',output)

if __name__=='__main__': main()

from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class BillingSignatureTests(unittest.TestCase):
    def test_actual_purchase_verifier_rejects_tampering_and_wrong_signatures(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            compiler = temp/'Compile.java'
            compiler.write_text('class Compile { public static void main(String[] args) { System.exit(javax.tools.ToolProvider.getSystemJavaCompiler().run(null,System.out,System.err,args)); } }')
            sources = [ROOT/'tools/android_billing/src/com/neonblockmaster/billing/PurchaseVerifier.java',
                       ROOT/'tests/android_billing/android/util/Base64.java',
                       ROOT/'tests/android_billing/PurchaseVerifierTest.java']
            subprocess.run(['java',str(compiler),'-d',str(temp),*map(str,sources)],capture_output=True,text=True,check=True)
            result = subprocess.run(['java','-cp',str(temp),'PurchaseVerifierTest'],capture_output=True,text=True,check=True)
            self.assertIn('passed: 14',result.stdout)

if __name__=='__main__': unittest.main()

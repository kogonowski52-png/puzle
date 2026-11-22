import com.neonblockmaster.billing.PurchaseVerifier;
import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.Signature;
import java.util.Base64;

public class PurchaseVerifierTest {
    static int checks;
    static void check(boolean ok) { checks++; if (!ok) throw new AssertionError("Crypto check " + checks); }
    static String sign(KeyPair pair, String json) throws Exception {
        Signature signature = Signature.getInstance("SHA1withRSA");
        signature.initSign(pair.getPrivate());
        signature.update(json.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(signature.sign());
    }
    public static void main(String[] args) throws Exception {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        KeyPair pair = generator.generateKeyPair();
        String key = Base64.getEncoder().encodeToString(pair.getPublic().getEncoded());
        PurchaseVerifier verifier = new PurchaseVerifier(key);
        String json = "{\"packageName\":\"com.neonblockmaster.puzzle\",\"productId\":\"rescue_pack_10_20\",\"token\":\"ephemeral-test-token\"}";
        String signature = sign(pair, json);
        check(verifier.verify(json, signature));
        check(!verifier.verify(json.replace("10_20", "100_200"), signature));
        check(!verifier.verify(json.replace("puzzle", "other"), signature));
        check(!verifier.verify(json, "invalid@@@"));
        check(!verifier.verify(json, ""));
        check(!verifier.verify("", signature));
        check(!verifier.verify(null, signature));
        check(!verifier.verify(json, null));
        KeyPair other = generator.generateKeyPair();
        check(!verifier.verify(json, sign(other, json)));
        String hash = PurchaseVerifier.receiptId("ephemeral-test-token");
        check(hash.matches("[0-9a-f]{64}"));
        check(hash.equals(PurchaseVerifier.receiptId("ephemeral-test-token")));
        check(!hash.equals(PurchaseVerifier.receiptId("different-token")));
        boolean refused = false;
        try { new PurchaseVerifier("not-a-key"); } catch (Exception expected) { refused = true; }
        check(refused);
        generator.initialize(1024);
        refused = false;
        try { new PurchaseVerifier(Base64.getEncoder().encodeToString(generator.generateKeyPair().getPublic().getEncoded())); }
        catch (Exception expected) { refused = true; }
        check(refused);
        System.out.println("Purchase signature checks passed: " + checks);
    }
}

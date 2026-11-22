// SPDX-License-Identifier: MIT
package com.neonblockmaster.billing;

import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.MessageDigest;
import java.security.PublicKey;
import java.security.Signature;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.X509EncodedKeySpec;
import android.util.Base64;

/** Verifies the Play Console licensing signature, not an app-signing certificate. */
public final class PurchaseVerifier {
    private final PublicKey key;
    public PurchaseVerifier(String encoded) throws Exception {
        byte[] bytes = Base64.decode(encoded.replaceAll("\\s", ""), Base64.DEFAULT);
        key = KeyFactory.getInstance("RSA").generatePublic(new X509EncodedKeySpec(bytes));
        if (((RSAPublicKey) key).getModulus().bitLength() < 2048) throw new IllegalArgumentException("RSA key too short");
    }
    public boolean verify(String json, String signed) {
        if (json == null || json.isEmpty() || signed == null || signed.isEmpty()) return false;
        try {
            Signature verifier = Signature.getInstance("SHA1withRSA");
            verifier.initVerify(key);
            verifier.update(json.getBytes(StandardCharsets.UTF_8));
            return verifier.verify(Base64.decode(signed, Base64.DEFAULT));
        } catch (Exception invalid) { return false; }
    }
    public static String receiptId(String token) throws Exception {
        byte[] bytes = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8));
        StringBuilder result = new StringBuilder(64);
        for (byte value : bytes) result.append(String.format("%02x", value & 255));
        return result.toString();
    }
}

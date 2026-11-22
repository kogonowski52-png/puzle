// SPDX-License-Identifier: MIT
package com.neonblockmaster.billing;

import android.app.Activity;
import com.android.billingclient.api.*;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.*;

/** One-time Google Play purchases only. Never logs raw purchase tokens or receipts. */
public final class NeonBilling extends GodotPlugin implements PurchasesUpdatedListener {
    public static final String PLUS = "neon_plus";
    public static final String PACK = "rescue_pack_10_20";
    private BillingClient client;
    private PurchaseVerifier verifier;
    private final Map<String, ProductDetails> products = new HashMap<>();
    private final Map<String, Purchase> deliveries = new HashMap<>();
    private final Set<String> settling = new HashSet<>();
    private boolean connecting;
    private boolean querying;
    private boolean flowActive;

    public NeonBilling(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "NeonBilling"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return Collections.singleton(new SignalInfo("billing_event", String.class));
    }
    private void event(String type, Object... values) {
        try {
            JSONObject payload = new JSONObject().put("type", type);
            for (int i = 0; i < values.length; i += 2) payload.put((String) values[i], values[i + 1]);
            emitSignal("billing_event", payload.toString());
        } catch (Exception invalid) { /* Fixed internal event schema. */ }
    }
    private void error(String code) { event("error", "code", code); }
    private void ui(Runnable task) {
        Activity activity = getActivity();
        if (activity == null) { error("unavailable"); return; }
        activity.runOnUiThread(task);
    }
    @UsedByGodot public void start(String publicKey) {
        ui(() -> {
            if (client != null) { connect(); return; }
            try { verifier = new PurchaseVerifier(publicKey); }
            catch (Exception invalid) { error("configuration_required"); return; }
            client = BillingClient.newBuilder(getActivity())
                .setListener(this)
                .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
                .enableAutoServiceReconnection().build();
            connect();
        });
    }
    private void connect() {
        if (client == null || connecting) return;
        if (client.isReady()) { refresh(); return; }
        connecting = true;
        client.startConnection(new BillingClientStateListener() {
            @Override public void onBillingSetupFinished(BillingResult result) {
                ui(() -> {
                    connecting = false;
                    if (result.getResponseCode() != BillingClient.BillingResponseCode.OK) { error("unavailable"); return; }
                    event("connected");
                    refresh();
                });
            }
            @Override public void onBillingServiceDisconnected() {
                ui(() -> { connecting = false; flowActive = false; error("disconnected"); });
            }
        });
    }
    private void refresh() {
        if (client == null || !client.isReady()) return;
        event("connected");
        List<QueryProductDetailsParams.Product> requested = new ArrayList<>();
        for (String id : Arrays.asList(PLUS, PACK)) requested.add(QueryProductDetailsParams.Product.newBuilder()
            .setProductId(id).setProductType(BillingClient.ProductType.INAPP).build());
        client.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(requested).build(),
            (result, details) -> ui(() -> {
                if (result.getResponseCode() != BillingClient.BillingResponseCode.OK) { error("catalog_unavailable"); return; }
                products.clear();
                JSONArray catalog = new JSONArray();
                for (ProductDetails item : details.getProductDetailsList()) {
                    if (!Arrays.asList(PLUS, PACK).contains(item.getProductId())) continue;
                    ProductDetails.OneTimePurchaseOfferDetails offer = item.getOneTimePurchaseOfferDetails();
                    // Only the default one-time buy option; no rental, subscription or timed offer.
                    if (offer == null || offer.getRentalDetails() != null) continue;
                    products.put(item.getProductId(), item);
                    try { catalog.put(new JSONObject().put("id", item.getProductId())
                        .put("price", offer.getFormattedPrice()).put("currency", offer.getPriceCurrencyCode())
                        .put("amount_micros", offer.getPriceAmountMicros())); }
                    catch (Exception invalid) { products.remove(item.getProductId()); }
                }
                event("catalog", "products", catalog);
            }));
        queryOwned();
    }
    @UsedByGodot public void buy(String id) {
        ui(() -> {
            if (client == null || !client.isReady() || flowActive) { error("unavailable"); return; }
            ProductDetails product = products.get(id);
            if (product == null) { error("catalog_unavailable"); return; }
            ProductDetails.OneTimePurchaseOfferDetails offer = product.getOneTimePurchaseOfferDetails();
            if (offer == null) { error("catalog_unavailable"); return; }
            BillingFlowParams.ProductDetailsParams.Builder item = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(product);
            if (offer.getOfferToken() != null && !offer.getOfferToken().isEmpty()) item.setOfferToken(offer.getOfferToken());
            flowActive = true;
            BillingResult result = client.launchBillingFlow(getActivity(), BillingFlowParams.newBuilder()
                .setProductDetailsParamsList(Collections.singletonList(item.build())).build());
            if (result.getResponseCode() != BillingClient.BillingResponseCode.OK) {
                flowActive = false;
                if (result.getResponseCode() == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED) queryOwned();
                error("unavailable");
            }
        });
    }
    @Override public void onPurchasesUpdated(BillingResult result, List<Purchase> purchases) {
        ui(() -> {
            flowActive = false;
            if (result.getResponseCode() == BillingClient.BillingResponseCode.USER_CANCELED) { event("cancelled"); return; }
            if (result.getResponseCode() == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED) { queryOwned(); return; }
            if (result.getResponseCode() != BillingClient.BillingResponseCode.OK || purchases == null) { error("unavailable"); return; }
            for (Purchase purchase : purchases) deliver(purchase);
        });
    }
    private boolean valid(Purchase purchase) {
        return verifier != null && purchase.getProducts().size() == 1 && purchase.getQuantity() == 1
            && Arrays.asList(PLUS, PACK).contains(purchase.getProducts().get(0))
            && getActivity() != null && getActivity().getPackageName().equals(purchase.getPackageName())
            && !purchase.getPurchaseToken().isEmpty()
            && verifier.verify(purchase.getOriginalJson(), purchase.getSignature());
    }
    private boolean deliver(Purchase purchase) {
        if (purchase.getPurchaseState() == Purchase.PurchaseState.PENDING) { event("pending"); return false; }
        if (purchase.getPurchaseState() != Purchase.PurchaseState.PURCHASED || !valid(purchase)) { error("verification_failed"); return false; }
        try {
            String receipt = PurchaseVerifier.receiptId(purchase.getPurchaseToken());
            deliveries.put(receipt, purchase);
            event("verified", "id", purchase.getProducts().get(0), "receipt", receipt);
            return true;
        } catch (Exception invalid) { error("verification_failed"); return false; }
    }
    @UsedByGodot public void restore() { ui(() -> { if (client == null) error("unavailable"); else connect(); }); }
    private void queryOwned() {
        if (querying || client == null || !client.isReady()) return;
        querying = true;
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build(),
            (result, purchases) -> ui(() -> {
                querying = false;
                if (result.getResponseCode() != BillingClient.BillingResponseCode.OK) { error("restore_failed"); return; }
                boolean plus = false, pending = false, invalid = false;
                for (Purchase purchase : purchases) {
                    if (purchase.getPurchaseState() == Purchase.PurchaseState.PENDING) { pending = true; event("pending"); continue; }
                    boolean verified = deliver(purchase);
                    if (!verified) invalid = true;
                    if (verified && purchase.getProducts().contains(PLUS)) plus = true;
                }
                // An invalid receipt or failed query cannot authoritatively revoke ownership.
                if (!invalid) event("ownership", "plus", plus, "pending", pending);
            }));
    }
    @UsedByGodot public void finish(String receipt) {
        ui(() -> {
            Purchase purchase = deliveries.get(receipt);
            if (purchase == null || client == null || !client.isReady() || settling.contains(receipt)) return;
            settling.add(receipt);
            if (purchase.getProducts().contains(PACK)) {
                client.consumeAsync(ConsumeParams.newBuilder().setPurchaseToken(purchase.getPurchaseToken()).build(),
                    (result, token) -> ui(() -> settled(receipt, result,
                        result.getResponseCode() == BillingClient.BillingResponseCode.ITEM_NOT_OWNED)));
            } else if (purchase.isAcknowledged()) {
                settled(receipt, BillingResult.newBuilder().setResponseCode(BillingClient.BillingResponseCode.OK).build(), false);
            } else {
                client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.getPurchaseToken()).build(),
                    result -> ui(() -> settled(receipt, result, false)));
            }
        });
    }
    private void settled(String receipt, BillingResult result, boolean alreadyConsumed) {
        settling.remove(receipt);
        if (result.getResponseCode() == BillingClient.BillingResponseCode.OK || alreadyConsumed) {
            deliveries.remove(receipt);
            event("settled", "receipt", receipt);
        } else error("settlement_pending"); // Inventory is durable; retry on next query/resume.
    }
    @Override public void onMainResume() {
        super.onMainResume();
        ui(() -> { if (client != null && !flowActive) connect(); });
    }
    @Override public void onMainDestroy() {
        if (client != null) client.endConnection();
        super.onMainDestroy();
    }
}

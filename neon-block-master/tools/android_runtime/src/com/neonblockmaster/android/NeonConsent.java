// SPDX-License-Identifier: MIT
package com.neonblockmaster.android;

import android.app.Activity;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.UserMessagingPlatform;
import org.godotengine.godot.Dictionary;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/** UMP operations are dispatched to Android's UI thread, never the Godot render thread. */
public final class NeonConsent extends GodotPlugin {
    public NeonConsent(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "NeonConsent"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(new SignalInfo("on_consent_info_updated_success"),
            new SignalInfo("on_consent_info_updated_failure", Dictionary.class)));
    }
    private void fail(int code, String message) {
        Dictionary error = new Dictionary();
        error.put("error_code", code);
        error.put("message", message);
        emitSignal("on_consent_info_updated_failure", error);
    }
    @UsedByGodot public void update(Dictionary values) {
        Activity activity = getActivity();
        if (activity == null) { fail(-1,"Android activity is unavailable"); return; }
        final boolean underAge = !Boolean.FALSE.equals(values.get("tag_for_under_age_of_consent"));
        activity.runOnUiThread(() -> {
            try {
                ConsentRequestParameters parameters = new ConsentRequestParameters.Builder()
                    .setTagForUnderAgeOfConsent(underAge).build();
                UserMessagingPlatform.getConsentInformation(activity).requestConsentInfoUpdate(activity, parameters,
                    () -> emitSignal("on_consent_info_updated_success"),
                    error -> fail(error.getErrorCode(),error.getMessage()));
            } catch (RuntimeException error) {
                fail(-1,error.getClass().getSimpleName()+": "+String.valueOf(error.getMessage()));
            }
        });
    }
    @UsedByGodot public int get_consent_status() {
        Activity activity = getActivity();
        return activity == null ? ConsentInformation.ConsentStatus.UNKNOWN
            : UserMessagingPlatform.getConsentInformation(activity).getConsentStatus();
    }
    @UsedByGodot public boolean get_is_consent_form_available() {
        Activity activity = getActivity();
        return activity != null && UserMessagingPlatform.getConsentInformation(activity).isConsentFormAvailable();
    }
    @UsedByGodot public void reset() {
        Activity activity = getActivity();
        if (activity != null) activity.runOnUiThread(() -> UserMessagingPlatform.getConsentInformation(activity).reset());
    }
}

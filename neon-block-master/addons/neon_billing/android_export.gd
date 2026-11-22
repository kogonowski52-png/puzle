@tool
extends EditorExportPlugin
func _get_name() -> String: return "NeonPlayBilling"
func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid
func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	return PackedStringArray(["res://addons/neon_billing/runtime/neon-billing.aar"])
func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	return PackedStringArray(["com.android.billingclient:billing:8.0.0"])
func _get_android_manifest_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
	return '<uses-permission android:name="com.android.vending.BILLING" />\n<uses-feature xmlns:tools="http://schemas.android.com/tools" android:name="android.hardware.screen.portrait" android:required="false" tools:replace="android:required" />'

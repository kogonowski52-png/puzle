# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Neon Block Master contributors.
@tool
extends EditorExportPlugin
func _get_name() -> String: return "NeonClassicGoogleAds"
func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid
func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	var variant := "debug" if debug else "release"
	var libraries := PackedStringArray([
		"res://addons/admob/android/bin/ads/libs/poing-godot-admob-ads-"+variant+".aar",
		"res://addons/admob/android/bin/ads/libs/poing-godot-admob-core-"+variant+".aar",
		"res://addons/neon_ads/runtime/neon-webview.aar"])
	if debug and ProjectSettings.get_setting("neon/debug_startup_report",false) and FileAccess.file_exists("res://addons/neon_ads/diagnostics/startup-diagnostics-debug.aar"):
		_enable_debug_crash_report()
		libraries.append("res://addons/neon_ads/diagnostics/startup-diagnostics-debug.aar")
	return libraries

func _enable_debug_crash_report() -> void:
	# Godot writes this overlay before asking for the libraries. The launcher
	# remains in a separate process so a native game crash cannot hide its report.
	var path := "res://android/build/src/debug/AndroidManifest.xml"
	var manifest := FileAccess.get_file_as_string(path)
	if manifest.contains("com.neonblockmaster.diagnostics.StartupActivity"): return
	var alias_regex := RegEx.new()
	alias_regex.compile("<activity-alias\\s[^>]*>")
	var found := alias_regex.search(manifest)
	if found == null:
		push_error("Cannot install debug crash reporter: launcher alias is missing")
		return
	var alias := found.get_string()
	alias = alias.replace("android:targetActivity=\".GodotApp\"", "android:targetActivity=\"com.neonblockmaster.diagnostics.StartupActivity\"")
	alias = alias.replace("<activity-alias", "<activity-alias tools:replace=\"android:targetActivity\"")
	var components := """
<activity android:name="com.neonblockmaster.diagnostics.StartupActivity" android:process=":diagnostics" android:exported="false" android:screenOrientation="portrait" android:theme="@android:style/Theme.Material.NoActionBar" />
<provider android:name="com.neonblockmaster.diagnostics.ReportProvider" android:process=":diagnostics" android:authorities="${applicationId}.diagnostics" android:exported="false" android:grantUriPermissions="true" />
"""
	manifest = manifest.substr(0,found.get_start())+components+alias+manifest.substr(found.get_end())
	manifest = manifest.replace("<application ","<application android:name=\"com.neonblockmaster.diagnostics.CrashApplication\" ")
	var output := FileAccess.open(path,FileAccess.WRITE)
	if output == null:
		push_error("Cannot save debug crash reporter manifest")
		return
	output.store_string(manifest)
func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	return PackedStringArray(["com.google.android.gms:play-services-ads:24.9.0","com.google.android.ump:user-messaging-platform:4.0.0","androidx.appcompat:appcompat:1.7.1","com.google.android.material:material:1.13.0"])
func _get_android_manifest_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
	return """
<uses-permission xmlns:tools="http://schemas.android.com/tools" android:name="android.permission.AD_ID" tools:node="remove" />
<uses-permission xmlns:tools="http://schemas.android.com/tools" android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />
<uses-permission xmlns:tools="http://schemas.android.com/tools" android:name="android.permission.ACCESS_ADSERVICES_AD_ID" tools:node="remove" />
<uses-permission xmlns:tools="http://schemas.android.com/tools" android:name="android.permission.ACCESS_ADSERVICES_TOPICS" tools:node="remove" />
<uses-permission xmlns:tools="http://schemas.android.com/tools" android:name="android.permission.ACCESS_ADSERVICES_ATTRIBUTION" tools:node="remove" />
<uses-permission xmlns:tools="http://schemas.android.com/tools" android:name="android.permission.READ_PHONE_STATE" tools:node="remove" />
<uses-permission xmlns:tools="http://schemas.android.com/tools" android:name="android.permission.READ_BASIC_PHONE_STATE" tools:node="remove" />
"""
func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
	var config = JSON.parse_string(FileAccess.get_file_as_string("res://assets/app_config.json"))
	var app_id: String = config.admob.app_id
	return """
<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="%s" />
<meta-data android:name="com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT" android:value="true" />
""" % app_id

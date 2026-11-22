# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Neon Block Master contributors.
@tool
extends EditorPlugin
var android_exporter = preload("res://addons/neon_ads/android_export.gd").new()
var registered := false
func _enter_tree() -> void:
	var config = JSON.parse_string(FileAccess.get_file_as_string("res://assets/app_config.json"))
	if config is Dictionary and config.get("ads_enabled",false) and config.get("ad_profile","")=="family_contextual" and config.get("ad_sdk","")=="gma_classic_24.9.0":
		_remove_next_gen_exclusions()
		add_export_plugin(android_exporter)
		registered = true
func _exit_tree() -> void:
	if registered: remove_export_plugin(android_exporter)

func _remove_next_gen_exclusions() -> void:
	# The old upstream editor plugin appended this block to the generated template.
	# Keeping it silently drops the classic SDK while still packaging its wrapper.
	var path := "res://android/build/build.gradle"
	if not FileAccess.file_exists(path): return
	var content := FileAccess.get_file_as_string(path)
	var legacy := "\n// Added by Poing Godot AdMob Plugin to support GMA Next-Gen SDK\nconfigurations.configureEach {\n    exclude group: \"com.google.android.gms\", module: \"play-services-ads\"\n    exclude group: \"com.google.android.gms\", module: \"play-services-ads-lite\"\n    resolutionStrategy.force \"androidx.browser:browser:1.8.0\"\n}\n"
	if not content.contains(legacy): return
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		push_error("Cannot remove obsolete Next-Gen exclusions from Android build template")
		return
	file.store_string(content.replace(legacy,"\n"))
	print("Removed obsolete Next-Gen exclusions; classic Google Mobile Ads can be packaged")

extends Node
## Everyone receives the same child-directed, under-age, G-rated ad profile.
## No birth date or age choice is needed to obtain more permissive advertising.
const PATH := "res://assets/app_config.json"
var data: Dictionary = {}
func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary: data = parsed
func production() -> bool: return data.get("mode","test")=="production"
func ad_id(kind: String) -> String:
	return str(data.get("admob",{}).get(kind+"_id",""))
func audience_configured() -> bool:
	return data.get("audience","") in ["mixed","children","16+","18+"]
func child_profile() -> bool:
	return data.get("ad_profile","")=="family_contextual"
func advertising_enabled() -> bool:
	return data.get("ads_enabled",false)==true and audience_configured() and child_profile() and data.get("ad_sdk","")=="gma_classic_24.9.0"
func age_choice_required() -> bool: return false
func ads_allowed() -> bool:
	if not advertising_enabled(): return false
	if OS.has_feature("production") and not production(): return false
	if not production(): return true
	for key in ["app","rewarded","interstitial"]:
		var value := ad_id(key)
		if value.is_empty() or value.contains("3940256099942544"): return false
	return true

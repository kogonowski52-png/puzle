extends RefCounted
## One action, one fresh challenge. No birth date or age profile is collected.
var left: int
var right: int
var expires_at: int
var used := false

func _init() -> void:
	left = randi_range(12,29)
	right = randi_range(12,29)
	expires_at = Time.get_ticks_msec()+120000

func accept(answer: String) -> bool:
	if used or Time.get_ticks_msec()>expires_at: return false
	used = true
	return answer.strip_edges().is_valid_int() and int(answer)==left*right

extends "res://scripts/admob_adapter.gd"
## Observe load ordering without making any native ad requests.
var loads := 0
func load_rewarded(): loads += 1
func load_interstitial(): loads += 1

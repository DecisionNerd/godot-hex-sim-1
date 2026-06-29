extends RefCounted

var id: String = ""
var display_name: String = ""
var hex_coords: Vector2i = Vector2i.ZERO
var rules: Array = []
## Work-units this person contributes to the household labour pool each day.
var daily_labor: int = 5


func roll_action(rng: RandomNumberGenerator) -> String:
	if rules.is_empty():
		return "idle"
	var roll := rng.randf()
	var cumulative := 0.0
	for rule in rules:
		cumulative += rule["probability"]
		if roll < cumulative:
			return rule["action"]
	return rules[rules.size() - 1]["action"]

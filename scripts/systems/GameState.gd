extends Node

# Run-wide data (should survive scene changes)

var gold : int = 0
var current_stage : int = 1
var player_stats = {}
var collected_psychore : int = 0
var duumite_shards : int = 0

func add_gold(amount: int) -> void:
	gold += amount
	emit_signal("gold_changed", gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		emit_signal("gold_changed", gold)
		return true
	return false	

signal gold_changed(new_amount)

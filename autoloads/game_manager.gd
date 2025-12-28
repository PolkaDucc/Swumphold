extends Node

#currency
var golden_maggots: int = 0
var duumite_shards: int = 0
var gastromats: int = 0

#run state
var current_stage: int = 0
var current_room: int = 0
var is_run_active: bool = false

#eventbus reference for convenience :D
@onready var events: Node = get_node("/root/EventBus")

func start_run() -> void:
	golden_maggots = 0
	duumite_shards = 0
	gastromats = 0
	current_stage = 0
	current_room = 0
	is_run_active = true

func end_run() -> void:
	is_run_active = false

func add_gm(amount: int) -> void:
	golden_maggots += amount
	events.gm_changed.emit(golden_maggots)  

func spend_gm(amount: int) -> bool:
	if golden_maggots >= amount:
		golden_maggots -= amount
		events.gm_changed.emit(golden_maggots)
		return true
	return false

func add_duumite(amount: int) -> void:
	duumite_shards += amount
	events.duumite_changed.emit(duumite_shards)

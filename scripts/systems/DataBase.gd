extends Node

# load json tables on startup so other scripts can query :D (Hi jason!)

var weapon_table = {}
var enemy_table = {}

func _ready() -> void:
	load_weapon_data()
	load_enemy_data()

func load_weapon_data() -> void:
	var file = FileAccess.open("res://data/weapons.json", FileAccess.READ)
	if file: 
		weapon_table = JSON.parse(file.get_as_text()).result
		file.close()

func load_enemy_data() -> void:
	var file = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if file: 
		enemy_table = JSON.parse(file.get_as_text()).result
		file.close()

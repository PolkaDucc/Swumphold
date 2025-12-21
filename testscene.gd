extends Node2D

func _ready() -> void:
	print("[DEBUG] Gold from GameState:", GameState.gold)  
	print("[DEBUG] Weapon table keys:", Database.weapon_table.keys())
	print("[DEBUG] Enemy table keys :", Database.enemy_table.keys())

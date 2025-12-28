class_name EnemyData
extends Resource

enum EnemyFaction { RABANDIT, QXTECH, DUUMITE }

@export var enemy_name: String = ""
@export var faction: EnemyFaction = EnemyFaction.RABANDIT
@export var quality: int = 1

@export var health: int = 50
@export var defense: int = 15
@export var damage: int = 7
@export var move_speed: float = 1.0

@export_multiline var description: String = ""
@export var is_infamous: bool = false

@export var sprite_texture: Texture2D

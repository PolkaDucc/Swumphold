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

#ai config
@export var aggro_range: float = 150.0
@export var attack_range: float = 20.0
@export var preferred_state: Enums.EnemyState = Enums.EnemyState.ATTACK_CLOSE
@export var is_ranged: bool = false
@export var can_heal: bool = false
@export var can_buff: bool = false
@export var can_shield: bool = false
@export var can_spawn: bool = false

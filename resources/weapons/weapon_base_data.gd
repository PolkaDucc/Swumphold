class_name WeaponBaseData
extends Resource

@export var weapon_type: Enums.WeaponType
@export var weapon_name: String = ""

@export var base_damage: int = 5
@export var base_puncture: int = 0
@export var base_accuracy_min: int = 80
@export var base_accuracy_max: int = 100
@export var base_fire_rate: float = 2.0
@export var base_magazine_size: int = 12
@export var base_crit_chance: float = 0.10
@export var base_crit_damage: float = 2.0
@export var base_projectile_count: int = 1
@export var base_reload_speed: float = 2.0

@export var part_types: Array[Enums.PartType] = []

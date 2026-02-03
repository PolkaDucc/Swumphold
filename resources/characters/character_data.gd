class_name CharacterData
extends Resource

@export var character_name: String = ""
@export var max_health: int = 100
@export var defense: int = 0
@export var move_speed_multiplier: float = 1.0
@export var elemental_damage: float = 0.0
@export var difficulty: float = 0.0
@export var lifesteal: float = 0.0
@export var healing: float = 1.0
@export var regen: float = 0.0
@export var starting_weapon_type: Enums.WeaponType = Enums.WeaponType.PISTOL
@export var ability_name: String = ""
@export_multiline var ability_description: String = ""
@export var ability_cooldown: float = 8.0
@export var sprite_texture: Texture2D

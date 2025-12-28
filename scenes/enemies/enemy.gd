class_name Enemy
extends CharacterBody2D

@export var enemy_data: EnemyData

@onready var sprite: Sprite2D = $Sprite2D

const BASE_SPEED: float = 60.0

var current_health: int
var is_infamous: bool = false
var target: Node2D = null


func _ready() -> void:
	if enemy_data:
		current_health = enemy_data.health
	else:
		current_health = 50
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _physics_process(delta: float) -> void:
	if target:
		_move_toward_target()
	move_and_slide()

func _move_toward_target() -> void:
	var direction = (target.global_position - global_position).normalized()
	var speed = BASE_SPEED * enemy_data.move_speed if enemy_data else BASE_SPEED
	velocity = direction * speed

func take_damage(amount: int) -> void:
	current_health -= amount
	print(enemy_data.enemy_name if enemy_data else "Enemy", " took ", amount, " damage! HP: ", current_health)
	if current_health <= 0:
		_die()

func _die() -> void:
	print(enemy_data.enemy_name if enemy_data else "Enemy", " died!")
	queue_free()

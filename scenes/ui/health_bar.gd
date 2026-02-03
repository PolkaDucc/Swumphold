class_name EnemyHealthBar
extends Control

@onready var name_label: Label = $NameLabel
@onready var level_label: Label = $LevelLabel
@onready var damage_bar: ProgressBar = $DamageBar
@onready var hp_bar: ProgressBar = $HealthBar
@onready var tick_container: Control = $TickContainer

var max_health: int = 100
var current_health: int = 100
var enemy_level: int = 1
var hide_timer: float = 0.0
var damage_bar_tween: Tween


func setup(enemy_name: String, modifiers: String, health: int, level: int) -> void:
	max_health = health
	current_health = health
	enemy_level = level
	
	await get_tree().process_frame

	if modifiers != "":
		name_label.text = modifiers + " " + enemy_name
	else:
		name_label.text = enemy_name

	level_label.text = str(level)
	var level_ratio = clamp((level - 1) / 29.0, 0.0, 1.0)
	level_label.modulate = Color(1, 1 - level_ratio, 1 - level_ratio)

	hp_bar.max_value = max_health
	hp_bar.value = max_health
	damage_bar.max_value = max_health
	damage_bar.value = max_health

	tick_container.setup(max_health)


func update_health(new_health: int) -> void:
	current_health = new_health
	hp_bar.value = current_health

	if damage_bar_tween:
		damage_bar_tween.kill()
	damage_bar_tween = create_tween()
	damage_bar_tween.tween_property(damage_bar, "value", current_health, 0.5).set_ease(Tween.EASE_OUT)

	hide_timer = 2.0
	show()


func _process(delta: float) -> void:
	if hide_timer > 0:
		hide_timer -= delta
		if hide_timer <= 0:
			hide()

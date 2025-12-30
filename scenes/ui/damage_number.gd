class_name DamageNumber
extends Label

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 100.0
var lifetime: float = 0.8
var shake_amount: float = 0.0
var shake_decay: float = 10.0

enum DamageType { NORMAL, FIRE, FREEZE, CORRUPT, BLEED, SHOCK, INFECTED, DUUMITE, CRIT }


func setup(amount: int, damage_type: DamageType = DamageType.NORMAL) -> void:
	text = str(amount)
	
	velocity = Vector2(randf_range(-30, 30), -80)
	
	if amount < 15:
		shake_amount = 0.0
	else:
		shake_amount = clamp((amount - 15) / 30.0, 0.0, 15.0)

	var color: Color
	match damage_type:
		DamageType.NORMAL:
			color = Color(1.0, 1.0, 1.0)
		DamageType.FIRE:
			color = Color(1.0, 0.4, 0.1)
		DamageType.FREEZE:
			color = Color(0.0, 0.9, 1.0, 1.0)
		DamageType.CORRUPT:
			color = Color(0.6, 0.2, 0.8)
		DamageType.BLEED:
			color = Color(0.8, 0.1, 0.1)
		DamageType.SHOCK:
			color = Color(1.0, 1.0, 0.3)
		DamageType.INFECTED:
			color = Color(0.4, 0.7, 0.2)
		DamageType.DUUMITE:
			color = Color(1.0, 0.4, 0.8)
		DamageType.CRIT:
			color = Color(0.0, 0.8, 0.6, 1.0)
	
	add_theme_color_override("font_color", color)
	


func _process(delta: float) -> void:
	velocity.y += gravity * delta
	position += velocity * delta

	if shake_amount > 0:
		var shake_offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		position += shake_offset
		shake_amount = max(0, shake_amount - shake_decay * delta)
	
	lifetime -= delta
	modulate.a = lifetime / 0.8
	
	if lifetime <= 0:
		queue_free()

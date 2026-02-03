extends AnimatedSprite2D


func _ready() -> void:
	play("spawn")
	animation_finished.connect(_on_animation_finished)


func _on_animation_finished() -> void:
	queue_free()

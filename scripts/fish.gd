extends CharacterBody2D


const SPEED = 300.0

func _physics_process(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	velocity = (mouse_pos-global_position)*SPEED*delta
	rotation = velocity.angle()
	move_and_slide()

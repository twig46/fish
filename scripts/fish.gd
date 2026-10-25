extends CharacterBody2D


const SPEED = 40.0
const FRICTION = 4.0

var target_velocity: Vector2 = Vector2.ZERO

var children: Array[CharacterBody2D]

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_right"):
		take_damage()
	#var mouse_pos: Vector2 = $"../mouse".global_position
	#velocity = (mouse_pos-global_position)*SPEED*delta
	velocity = velocity.lerp(target_velocity, FRICTION*delta)
	if velocity.length() > 1.0:
		rotation = velocity.angle()
	move_and_slide()
	target_velocity.lerp(Vector2.ZERO, FRICTION*delta)
	
	if Engine.get_physics_frames() > 5:
		if !$notifier.is_on_screen():
			print("death")
		
	var camera = $"../cam"
	var viewport_size = get_viewport_rect().size
	var zoom = camera.zoom
	var cam_pos = camera.get_screen_center_position()
	
	var half_size = (viewport_size / 2.0) / zoom
	var min_bound = cam_pos - half_size
	var max_bound = cam_pos + half_size
	
	global_position.x = clamp(global_position.x, min_bound.x, max_bound.x)
	global_position.y = clamp(global_position.y, min_bound.y, max_bound.y)
	
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		target_velocity = event.relative*SPEED

func take_damage():
	$"../cam/shake".shake(0.4)
	if children.is_empty():
		get_parent().lose()
	else:
		var sacrifice = children[0]
		children.remove_at(0)
		sacrifice.queue_free()

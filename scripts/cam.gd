extends Camera2D

@onready var background_material: ShaderMaterial = $"../canvas/bg".material

func _process(_delta: float) -> void:
	#if Input.is_action_just_pressed("ui_accept"):
		#zoom_x(0.5)
	#if Input.is_action_just_pressed("shift"):
		#zoom_x(2)
	sync_background()

func sync_background() -> void:
	background_material.set_shader_parameter("camera_position", get_screen_center_position())
	background_material.set_shader_parameter("camera_zoom", zoom.x)
	background_material.set_shader_parameter("viewport_size", get_viewport_rect().size)

func zoom_x(amount: float, pos: Vector2 = global_position) -> void:
	get_tree().paused = true
	var in_tween = get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var out_tween = get_tree().create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var zoom_tween = in_tween if amount >= 1 else out_tween 
	var move_tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	zoom_tween.tween_property(self,"zoom",zoom*amount, 1)
	move_tween.tween_property(self,"global_position",pos, 1)
	await zoom_tween.finished
	sync_background()
	get_tree().paused = false
	Input.warp_mouse($"../fish".global_position)

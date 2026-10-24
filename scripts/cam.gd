extends Camera2D

@onready var background_material: ShaderMaterial = $"../CanvasLayer/ColorRect".material

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		zoom_out()
	if Input.is_action_just_pressed("shift"):
		zoom_in()
	background_material.set_shader_parameter("camera_position", global_position)
	background_material.set_shader_parameter("camera_zoom", 1.0 / zoom.x)

func zoom_out() -> void:
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"zoom",zoom/2, 1)

func zoom_in() -> void:
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"zoom",zoom*2, 1)

func get_bounds() -> Rect2:
	

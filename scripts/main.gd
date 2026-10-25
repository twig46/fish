extends Node2D

var child = preload("res://scenes/child.tscn")

var timer_running = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#for i in range(10):
		##var new_child = child.instantiate()
		##new_child.position.x = randi_range(1, 2000)
		##new_child.parent = $fish
		##$fish.children.push_back(new_child)
		##add_child(new_child)
		#spawn_child()

var timer = 0.0
var curtime = 0
var enemy_spawn_timer = 0.0
var enemy_spawn_interval = 6.0
var child_spawn_timer = 0.0
var child_spawn_interval = 0.0
func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("ui_left"):
		#lose()
	$UI/timer.visible = timer_running

	timer += delta
	if timer >= 6.0:
		rand_zoom()
		timer = 0.0

	if timer_running:
		curtime += delta
	if curtime >= 1.0:
		$UI/timer.text = str(max(int($UI/timer.text) - 1, 0))
		curtime -= 1.0
	$UI/score.text = str(len($fish.children))
	enemy_spawn_timer += delta
	child_spawn_timer+=delta

	if enemy_spawn_timer >= enemy_spawn_interval:
		spawn_enemy()
		enemy_spawn_timer = 0.0
		enemy_spawn_interval = randf_range(1, 10)
	if child_spawn_timer >= child_spawn_interval:
		print("child")
		spawn_child()
		child_spawn_timer = 0.0
		child_spawn_interval = randf_range(1, 3)

func rand_zoom():
	$box.visible = true
	var viewport = get_viewport_rect().size
	var current_anim = $box.animation
	var current_frame = $box.frame
	var texture = $box.sprite_frames.get_frame_texture(current_anim, current_frame)
	var visible_space = viewport / $cam.zoom
	var top_left = $cam.global_position - visible_space / 2
	
	var out: bool = randi_range(0, 1)
	var random = randi_range(2, 5)
	if $cam.zoom.x > 1:
		out = true
	if $cam.zoom.x <= 0.25:
		out = false
	if !out:
		var size = viewport / ($cam.zoom*random)
		if texture:
			$box.scale = size / texture.get_size()
		$box.global_position = Vector2(
			randf_range(top_left.x, top_left.x + visible_space.x - size.x),
			randf_range(top_left.y, top_left.y + visible_space.y - size.y)
		)
		timer_running = true
		$UI/timer.text = '5'
		await get_tree().create_timer(5).timeout
		$box.visible = false
		await $cam.zoom_x(random, $box.global_position + size / 2)
	else:
		var size = viewport / $cam.zoom
		if texture:
			$box.scale = size / texture.get_size()
		$box.global_position = top_left
		timer_running = true
		$UI/timer.text = '5'
		await get_tree().create_timer(5).timeout
		$box.visible = false
		await $cam.zoom_x(1.0/random)
	timer_running = false

var enemy = preload("res://scenes/octopus.tscn")

func spawn_enemy() -> void:
	var new_enemy = enemy.instantiate()

	var viewport = get_viewport_rect().size
	var visible_space = viewport / $cam.zoom
	var top_left = $cam.global_position - visible_space / 2

	new_enemy.position = Vector2(
		randf_range(top_left.x, top_left.x + visible_space.x),
		randf_range(top_left.y, top_left.y + visible_space.y)
	)
	add_child(new_enemy)
	

func spawn_child() -> void:
	var new_child = child.instantiate()

	var viewport = get_viewport_rect().size
	var visible_space = viewport / $cam.zoom
	var top_left = $cam.global_position - visible_space / 2

	new_child.position = Vector2(
		randf_range(top_left.x, top_left.x + visible_space.x),
		randf_range(top_left.y, top_left.y + visible_space.y)
	)
	add_child(new_child)

var main_scn = preload("res://scenes/main.tscn")

var is_dead = false

func lose():
	$UI/loss.visible = true
	$UI/losscolour.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	get_tree().paused = true
	is_dead = true

func _unhandled_input(event: InputEvent) -> void:
	if is_dead and event.is_pressed() and not event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		get_tree().call_deferred("reload_current_scene")

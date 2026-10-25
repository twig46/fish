extends CharacterBody2D

var projectile = preload("res://scenes/ball.tscn")

var max_cooldown = randf_range(1, 4)
var cooldown = max_cooldown
var projectile_speed = randf_range(300, 500)

func _process(delta: float) -> void:
	cooldown-=delta
	if cooldown <= 0:
		print("shot")
		shoot()
		cooldown = max_cooldown
	var colliders = $psb.get_overlapping_bodies()
	for collider in colliders:
		if collider.has_method("take_damage"):
			collider.take_damage()
			queue_free()
	var player_dir = ($"../fish".global_position-global_position).normalized()
	velocity = player_dir*10
	move_and_slide()


func shoot():
	var new_projectile = projectile.instantiate()
	new_projectile.speed = projectile_speed
	new_projectile.direction = ($"../fish".global_position-global_position).normalized()
	new_projectile.global_position = global_position
	$"..".add_child(new_projectile)

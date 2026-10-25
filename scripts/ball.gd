extends CharacterBody2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 0

@onready var psb = $psb

func _ready() -> void:
	velocity = direction*speed


func _physics_process(_delta: float) -> void:
	move_and_slide()
	rotate(0.1)
	var colliders = psb.get_overlapping_bodies()
	for collider in colliders:
		if collider.has_method("take_damage"):
			collider.take_damage()
			queue_free()

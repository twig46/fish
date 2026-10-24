extends CharacterBody2D

@export var parent: CharacterBody2D

const SPEED = 500.0
const PUSH_STRENGTH = 200.0

@onready var psb = $psb
@onready var sprite: Sprite2D = $sprite

const PALETTE: Array[Color] = [
	Color("#009b88"),
	Color("#2d272f"),
	Color("#415d99"),
	Color("#4f61a7"),
	Color("#524d4a"),
	Color("#5c719a"),
	Color("#6ea16e"),
	Color("#735fb1"),
	Color("#8f5676"),
	Color("#9196db"),
	Color("#91b4db"),
	Color("#97db91"),
	Color("#9d696a"),
	Color("#b991db"),
	Color("#d9d4d8"),
	Color("#db91d4"),
	#Color("#db9591"),
	Color("#dbaf91"),
	Color("#dbd991"),
	Color("#fbfbfb")
]

func _ready() -> void:
	#sprite.modulate = Color("#2d272f")
	sprite.modulate = PALETTE.pick_random()

func _physics_process(delta: float) -> void:
	var push_vector = Vector2.ZERO
	var overlapping_bodies = psb.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body == self or body is not CharacterBody2D:
			continue
		var diff: Vector2 = global_position-body.global_position
		var distance := diff.length()
		if distance > 0:
			push_vector+=diff.normalized()*(PUSH_STRENGTH/distance)
	velocity = push_vector*delta
	move_and_slide()
	velocity = (parent.global_position-global_position)*SPEED*delta
	rotation = velocity.angle()
	move_and_slide()
	#velocity = Vector2.ZERO

extends Node2D

var child = preload("res://child.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(40):
		var new_child = child.instantiate()
		new_child.position.x = randi_range(1, 2000)
		new_child.parent = $fish
		add_child(new_child)

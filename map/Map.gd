extends Node3D

@onready var dummy: = load("res://vehicle/Dummy.tscn")

func _ready() -> void:
	var train: Node3D = dummy.instantiate()
	add_child(train)

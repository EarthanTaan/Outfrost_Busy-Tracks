extends Node3D

@onready var paths: = $Paths

@onready var dummy: = load("res://vehicle/Dummy.tscn")

func _ready() -> void:
	var train: Train = dummy.instantiate()
	add_child(train)
	train.spawn(paths.entrance_segments[0])
	train.go(Segment.Side.Begin)

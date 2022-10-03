extends Node3D

@onready var paths: = $Paths

@onready var dummy: = load("res://vehicle/CommuterTrain.tscn")

var trains: Array[Train] = []

func _ready() -> void:
	var train: Train = dummy.instantiate()
	add_child(train)
	train.dest_platform = $Paths/PlatformSegment
	train.spawn(paths.entrance_segments[0])
	trains.append(train)

	train = dummy.instantiate()
	add_child(train)
	train.spawn($Paths/PlatformSegment2)
	trains.append(train)

func _process(delta: float) -> void:
	for train in trains:
		if train.run_state != Train.RunState.Idle:
			continue

		if train.dest.begin_signal_clear:
			var dest = train.dest.find_route_dest(Segment.Side.Begin)
			if dest:
				train.dest = dest
				train.go(Segment.Side.Begin)
		elif train.dest.end_signal_clear:
			var dest = train.dest.find_route_dest(Segment.Side.End)
			if dest:
				train.dest = dest
				train.go(Segment.Side.End)

extends Node3D

const SPAWN_INTERVALS: Array[float] = [
	60.0,
	30.0,
	20.0,
	20.0,
	20.0,
	20.0,
	20.0,
	20.0,
	10.0,
	10.0,
	10.0,
	10.0,
	10.0,
	10.0,
	10.0,
	10.0,
	10.0,
	10.0,
	10.0,
	10.0,
	20.0,
	20.0,
	20.0,
	20.0,
	20.0,
	20.0,
	30.0,
	30.0,
]

@onready var paths: = $Paths
@onready var dummy: = load("res://vehicle/CommuterTrain.tscn")

var trains: Array[Train] = []

var spawn_interval_idx: int = 0
var spawn_timer: float = SPAWN_INTERVALS[spawn_interval_idx]

func _ready() -> void:
	var train: Train = dummy.instantiate()
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

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_interval_idx += 1
		spawn_timer = SPAWN_INTERVALS[spawn_interval_idx]
		var entrance
		for i in range(8):
			entrance = paths.entrance_segments[randi() % paths.entrance_segments.size()]
			if !entrance.occupied:
				break
		if entrance.occupied:
			return
		var train: Train = dummy.instantiate()
		add_child(train)
		train.spawn(entrance)
		trains.append(train)

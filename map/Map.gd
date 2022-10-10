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

signal game_finished()

@onready var paths: = $Paths
@onready var dummy: = load("res://vehicle/CommuterTrain.tscn")

var trains: Array[Train] = []

var spawn_interval_idx: int = 0
var spawn_timer: float = SPAWN_INTERVALS[spawn_interval_idx]
var stopwatch: float = 0.0
var trains_dispatched: int = 0
var no_more_spawns: bool = false
var game_finished_emitted: bool = false

func _ready() -> void:
	reset()

func _process(delta: float) -> void:
	if no_more_spawns && trains.is_empty():
		if !game_finished_emitted:
			game_finished.emit()
			game_finished_emitted = true
	else:
		stopwatch += delta

	for train in trains:
		if train.run_state != Train.RunState.Idle:
			continue

		if train.dest.begin_signal_clear:
			var dest = train.dest.find_dest(Segment.Side.Begin)
			if dest:
				train.dest = dest
				train.go(Segment.Side.Begin)
		elif train.dest.end_signal_clear:
			var dest = train.dest.find_dest(Segment.Side.End)
			if dest:
				train.dest = dest
				train.go(Segment.Side.End)

	spawn_timer -= delta
	if spawn_timer <= 0.0 && !no_more_spawns:
		var entrance
		for i in range(8):
			entrance = paths.entrance_segments[randi() % paths.entrance_segments.size()]
			if !entrance.occupied:
				break
		if entrance.occupied:
			return

		var train: Train = dummy.instantiate()
		add_child(train)
		train.tree_exiting.connect(func(): self.trains.erase(train))
		train.gone.connect(func(): self.trains_dispatched += 1)
		train.spawn(entrance)
		trains.append(train)

		spawn_interval_idx += 1
		if spawn_interval_idx >= SPAWN_INTERVALS.size():
			no_more_spawns = true
		else:
			spawn_timer = SPAWN_INTERVALS[spawn_interval_idx]

func reset() -> void:
	for t in trains:
		t.destroy_deferred()
	trains.clear()

	var train: Train = dummy.instantiate()
	add_child(train)
	train.tree_exiting.connect(func(): self.trains.erase(train))
	train.gone.connect(func(): self.trains_dispatched += 1)
	train.spawn($Paths/PlatformSegment2)
	trains.append(train)

	spawn_interval_idx = 0
	spawn_timer = SPAWN_INTERVALS[spawn_interval_idx]
	stopwatch = 0.0
	trains_dispatched = 0
	no_more_spawns = false
	game_finished_emitted = false

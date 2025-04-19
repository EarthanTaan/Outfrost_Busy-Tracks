extends Node3D

const DAY_DURATION: float = 750.0
const SUN_START_ANGLE: float = - TAU * 0.375
const SUN_END_ANGLE: float = TAU * 0.375
const NIGHT_LIGHT_GLOW_START: float = 0.0
const NIGHT_LIGHT_GLOW_FULL: float = 0.8

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
@onready var directional_light: DirectionalLight3D = %DirectionalLight
@onready var environment: Environment = $WorldEnvironment.environment.duplicate()

var trains: Array[Train] = []

var spawn_interval_idx: int = 0
var spawn_timer: float = SPAWN_INTERVALS[spawn_interval_idx]
var stopwatch: float = 0.0
var trains_dispatched: int = 0
var no_more_spawns: bool = false
var game_finished_emitted: bool = false
var day_time_elapsed: float = 0.0

func _ready() -> void:
	$WorldEnvironment.environment = environment

	reset()

func _process(delta: float) -> void:
	day_time_elapsed = fmod(day_time_elapsed + delta, DAY_DURATION)
	Daytime.set_time(day_time_elapsed / DAY_DURATION)
	directional_light.light_energy = Daytime.day_light * 1.25
	directional_light.rotation = Vector3(
		- TAU / 6.0,
		remap(day_time_elapsed, 0.0, DAY_DURATION, SUN_START_ANGLE, SUN_END_ANGLE),
		0.0)
	environment.glow_enabled = Daytime.night_light > NIGHT_LIGHT_GLOW_START
	environment.glow_intensity = 1.25 * clamp(
		remap(
			Daytime.night_light,
			NIGHT_LIGHT_GLOW_START,
			NIGHT_LIGHT_GLOW_FULL,
			0.0,
			1.0),
		0.0,
		1.0)

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
	directional_light.rotation_order = EULER_ORDER_XYZ
	directional_light.rotation = Vector3(deg_to_rad(- 60.0), TAU * 0.5, 0.0)

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
	day_time_elapsed = 0.0

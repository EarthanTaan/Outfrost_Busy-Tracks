class_name Train
extends Node3D

const MAX_SPEED: float = 15.0 # m/s

enum RunState {
	Idle,
	Moving,
	Stopping,
}

class CarMovement:
	var car: Node3D
	var path_follow: PathFollow3D
	var direction: Segment.Side = Segment.Side.End

	func _init(car: Node3D, offset: float, start: Segment) -> void:
		self.car = car
		path_follow = PathFollow3D.new()
		start.add_child(path_follow)
		path_follow.loop = false
		path_follow.rotation_mode = PathFollow3D.ROTATION_ORIENTED
		path_follow.progress_ratio = 0.5
		path_follow.progress += offset

	func update(speed: float, delta: float) -> void:
		if speed != 0.0:
			if direction == Segment.Side.End:
				path_follow.progress += speed * delta
				if path_follow.progress_ratio >= 1.0:
					var current_segment = path_follow.get_parent() as Segment
					cross_node(current_segment.end_node, current_segment)
			else:
				path_follow.progress -= speed * delta
				if path_follow.progress_ratio <= 0.0:
					var current_segment = path_follow.get_parent() as Segment
					cross_node(current_segment.begin_node, current_segment)

		car.global_transform = path_follow.global_transform

	func cross_node(path_node, current_segment: Segment) -> void:
		var next_segment = path_node.route_from(current_segment)
		if !next_segment:
			return

		current_segment.remove_child(path_follow)
		next_segment.add_child(path_follow)

		if next_segment.begin_node == path_node:
			direction = Segment.Side.End
			path_follow.progress_ratio = 0.0
		else:
			direction = Segment.Side.Begin
			path_follow.progress_ratio = 1.0

@export var accel: float = 2.0

var max_offset: float = 0.0
var current: Segment = null
var dest: Segment = null

var run_state: RunState = RunState.Idle
var speed: float = 0.0
var progress: Array[CarMovement] = []

func _ready() -> void:
	for car in get_children():
		car.hide()

func _process(delta: float) -> void:
	match run_state:
		RunState.Idle:
			pass
		RunState.Moving:
			speed = minf(speed + (accel * delta), MAX_SPEED)
		RunState.Stopping:
			speed = maxf(speed - (accel * delta), 0.0)

	for movement in progress:
		movement.update(speed, delta)

func spawn(at: Segment) -> void:
	current = at
	for car in get_children():
		max_offset = maxf(max_offset, car.position.z)
	for car in get_children():
		progress.append(CarMovement.new(car, car.position.z - (0.5 * max_offset), current))
		car.show.call_deferred()

func go(direction: Segment.Side) -> void:
	if run_state == RunState.Idle:
		for movement in progress:
			movement.direction = direction
		run_state = RunState.Moving

class_name Train
extends Node3D

const MAX_SPEED: float = 18.0 # m/s

enum RunState {
	Idle,
	Moving,
	Stopping,
	Loading,
}

class CarMovement:
	var car: Node3D
	var offset_from_middle: float
	var path_follow: PathFollow3D
	var segment_half_length: float
	var direction: Segment.Side = Segment.Side.End
	var flip: bool = false

	func _init(car: Node3D, offset: float, start: Segment) -> void:
		self.car = car
		offset_from_middle = offset
		reinit_path_follower()
		start.add_path_follow(path_follow)
		path_follow.progress_ratio = 0.5
		segment_half_length = path_follow.progress
		path_follow.progress += offset

	func reinit_path_follower() -> void:
		if path_follow:
			path_follow.get_parent().remove_path_follow(path_follow)
			path_follow.queue_free()
		path_follow = PathFollow3D.new()
		path_follow.loop = false
		path_follow.rotation_mode = PathFollow3D.ROTATION_ORIENTED

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

		if path_follow.is_inside_tree():
			car.global_transform = path_follow.global_transform
		if flip:
			car.rotate_y(TAU * 0.5)

	func distance_to_dest(dest: Segment) -> float:
		var result: = INF
		var current_segment: = path_follow.get_parent() as Segment
		if current_segment == dest:
			result = absf(path_follow.progress - segment_half_length) + absf(offset_from_middle)
		return result

	func cross_node(path_node, current_segment: Segment) -> void:
		var next_segment = path_node.route_from(current_segment)
		if !next_segment:
			return

		if current_segment.begin_node == path_node && !current_segment.begin_signal_always_clear:
			current_segment.begin_signal_clear = false
		if current_segment.end_node == path_node && !current_segment.end_signal_always_clear:
			current_segment.end_signal_clear = false

		reinit_path_follower()
		next_segment.add_path_follow(path_follow)

		path_follow.progress_ratio = 0.5
		segment_half_length = path_follow.progress

		var new_direction: Segment.Side
		if next_segment.begin_node == path_node:
			new_direction = Segment.Side.End
			path_follow.progress_ratio = 0.0
		else:
			new_direction = Segment.Side.Begin
			path_follow.progress_ratio = 1.0

		if new_direction != direction:
			flip = !flip
		direction = new_direction

signal gone()

@export var accel: float = 2.5
@export var loading_time: float = 30.0

var dest_platform: PlatformSegment = null
var dest_exit: ExitSegment = null

var max_offset: float = 0.0
var dest: Segment = null

var run_state: RunState = RunState.Idle
var speed: float = 0.0
var progress: Array[CarMovement] = []

var loading_time_remaining: float = 0.0

func _ready() -> void:
	for car in get_children():
		car.hide()

func _process(delta: float) -> void:
#	DebugOverlay.display(dest.name)
	match run_state:
		RunState.Idle:
			pass
		RunState.Moving:
			speed = minf(speed + (accel * delta), MAX_SPEED)
			var min_dist_to_dest: = INF
			for movement in progress:
				min_dist_to_dest = minf(min_dist_to_dest, movement.distance_to_dest(dest))
			if min_dist_to_dest <= 0.5 * (speed * speed / accel):
				run_state = RunState.Stopping
		RunState.Stopping:
			speed -= accel * delta
			if speed <= 0.0:
				speed = 0.0
				if dest is PlatformSegment:
					run_state = RunState.Loading
					loading_time_remaining = loading_time
				elif dest is ExitSegment:
					gone.emit()
					destroy_deferred()
				else:
					run_state = RunState.Idle
		RunState.Loading:
			loading_time_remaining -= delta
			if loading_time_remaining <= 0.0:
				run_state = RunState.Idle

	for movement in progress:
		movement.update(speed, delta)

func spawn(at: Segment) -> void:
	dest = at
	for car in get_children():
		max_offset = maxf(max_offset, car.position.z)
	for car in get_children():
		progress.append(CarMovement.new(car, car.position.z - (0.5 * max_offset), at))
		car.show.call_deferred()

func go(direction: Segment.Side) -> void:
	if run_state == RunState.Idle:
		for movement in progress:
			movement.direction = direction
		run_state = RunState.Moving

func destroy_deferred() -> void:
	for movement in progress:
		movement.path_follow.get_parent().remove_path_follow(movement.path_follow)
		movement.path_follow.queue_free()
	queue_free()

class_name Train
extends Node3D

class CarMovement:
	var car: Node3D
#	var offset: float
	var path_follow: PathFollow3D

	func _init(car: Node3D, offset: float, start: Segment) -> void:
		self.car = car
#		self.offset = offset
		path_follow = PathFollow3D.new()
		start.add_child(path_follow)
		path_follow.loop = false
		path_follow.rotation_mode = PathFollow3D.ROTATION_ORIENTED
		path_follow.progress_ratio = 0.5
		path_follow.progress += offset

var max_offset: float = 0.0
var current: Segment
var dest: Segment

var progress: Array[CarMovement] = []

func _process(delta: float) -> void:
	for movement in progress:
		movement.car.global_transform = movement.path_follow.global_transform

func spawn(at: Segment) -> void:
	current = at
	for car in get_children():
		max_offset = max(max_offset, car.position.z)
	for car in get_children():
		progress.append(CarMovement.new(car, car.position.z - (0.5 * max_offset), current))

#func go(from: Segment, to: Segment) -> void:
#	start = from
#	dest = to
#	for car in get_children():
#		progress.append(CarMovement.new(car, car.position.z, start))

extends Node3D

@onready var paths: = $Paths

@onready var dummy: = load("res://vehicle/CommuterTrain.tscn")

var trains: Array[Train] = []

func _ready() -> void:
	var train: Train = dummy.instantiate()
	add_child(train)
	train.dest_platform = $Paths/PlatformSegment1
	train.spawn(paths.entrance_segments[0])
	trains.append(train)

func _process(delta: float) -> void:
	for train in trains:
		if train.run_state != Train.RunState.Idle:
			continue

		if train.dest.begin_signal_clear:
			train.dest = find_route_dest(train.dest, train.dest.begin_node)
			train.go(Segment.Side.Begin)
		elif train.dest.end_signal_clear:
			train.dest = find_route_dest(train.dest, train.dest.end_node)
			train.go(Segment.Side.End)

func find_route_dest(start: Segment, last_node) -> Segment:
	var dest_segment: Segment = last_node.route_from(start)
	while dest_segment:
		if dest_segment.begin_node == last_node && dest_segment.end_signal_clear:
			last_node = dest_segment.end_node
			dest_segment = dest_segment.end_node.route_from(dest_segment)
		elif dest_segment.end_node == last_node && dest_segment.begin_signal_clear:
			last_node = dest_segment.begin_node
			dest_segment = dest_segment.begin_node.route_from(dest_segment)
		else:
			break
	return dest_segment

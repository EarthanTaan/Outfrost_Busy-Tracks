class_name Segment
extends Path3D

enum Side {
	Begin,
	End,
}

@export var begin_semaphore: NodePath
@export var end_semaphore: NodePath

@export var crossing_segments: Array[NodePath]

var begin_node
var end_node

var begin_signal_clear: bool = false:
	set(clear):
		begin_signal_clear = clear
		if !begin_semaphore.is_empty():
			get_node(begin_semaphore).clear_feedback(clear)
var begin_signal_always_clear: bool = false
var end_signal_clear: bool = false:
	set(clear):
		end_signal_clear = clear
		if !end_semaphore.is_empty():
			get_node(end_semaphore).clear_feedback(clear)
var end_signal_always_clear: bool = false

var occupied: bool = false
var followers: int = 0

func find_dest(side: Side) -> Segment:
	var last_node
	if side == Segment.Side.Begin:
		last_node = begin_node
	else:
		last_node = end_node

	if !last_node:
		return null

	var dest_segment: Segment = last_node.route_from(self)
	while dest_segment != null:
		if dest_segment.begin_node == last_node && dest_segment.end_signal_clear:
			last_node = dest_segment.end_node
			dest_segment = dest_segment.end_node.route_from(dest_segment)
		elif dest_segment.end_node == last_node && dest_segment.begin_signal_clear:
			last_node = dest_segment.begin_node
			dest_segment = dest_segment.begin_node.route_from(dest_segment)
		else:
			break
	return dest_segment

func find_route_dest(side: Side, route_segments: Array[Segment], route_nodes: Array) -> Segment:
	var last_node
	if side == Segment.Side.Begin:
		last_node = begin_node
	else:
		last_node = end_node

	if !last_node:
		return null

	var dest_segment: Segment = last_node.route_from(self)
	while dest_segment:
		if dest_segment.occupied:
			return null
		for crossing in dest_segment.crossing_segments:
			if !crossing.is_empty() && get_node(crossing).occupied:
				return null
		route_segments.append(dest_segment)
		route_nodes.append(last_node)
		if dest_segment.begin_node == last_node && dest_segment.end_signal_clear:
			last_node = dest_segment.end_node
			dest_segment = dest_segment.end_node.route_from(dest_segment)
		elif dest_segment.end_node == last_node && dest_segment.begin_signal_clear:
			last_node = dest_segment.begin_node
			dest_segment = dest_segment.begin_node.route_from(dest_segment)
		else:
			break
	return dest_segment

func add_path_follow(pf: PathFollow3D) -> void:
	add_child(pf)
	followers += 1
	occupied = true
	for crossing in crossing_segments:
		if !crossing.is_empty():
			get_node(crossing).occupied = true

func remove_path_follow(pf: PathFollow3D) -> void:
	remove_child(pf)
	followers -= 1
	if followers == 0:
		occupied = false
		for crossing in crossing_segments:
			if !crossing.is_empty():
				get_node(crossing).occupied = false

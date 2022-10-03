class_name Segment
extends Path3D

enum Side {
	Begin,
	End,
}

@export_node_path(TrackSemaphore) var begin_semaphore: NodePath
@export_node_path(TrackSemaphore) var end_semaphore: NodePath

@export var crossing_segments: Array[NodePath]

var begin_node
var end_node

var begin_signal_clear: bool = false
var begin_signal_always_clear: bool = false
var end_signal_clear: bool = false
var end_signal_always_clear: bool = false

var occupied: bool = false

func find_route_dest(side: Side, route = null) -> Segment:
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
		if route && route is Array:
			route.append(dest_segment)
		if dest_segment.begin_node == last_node && dest_segment.end_signal_clear:
			last_node = dest_segment.end_node
			dest_segment = dest_segment.end_node.route_from(dest_segment)
		elif dest_segment.end_node == last_node && dest_segment.begin_signal_clear:
			last_node = dest_segment.begin_node
			dest_segment = dest_segment.begin_node.route_from(dest_segment)
		else:
			break
	return dest_segment

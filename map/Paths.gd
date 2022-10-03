extends Node3D

class Link:
	var segment: Segment
	var side: Segment.Side
	var other_node: PathNode

	func _init(segment: Segment, side: Segment.Side, other_node: PathNode):
		self.segment = segment
		self.side = side
		self.other_node = other_node

	func _to_string() -> String:
		return "{segment: %s, side: %s, other_node: %d}" % [
			segment.name,
			side_str(),
			other_node.get_instance_id()
		]

	func side_str() -> String:
		match side:
			Segment.Side.Begin: return "Begin"
			Segment.Side.End: return "End"
			_: return "Unknown"

	func direction() -> Vector3:
		if side == Segment.Side.Begin:
			return (segment.curve.get_point_out(0) - segment.curve.get_point_position(0)).normalized()
		else:
			var idx: = segment.curve.point_count - 1
			return (segment.curve.get_point_in(idx) - segment.curve.get_point_position(idx)).normalized()

class PathNode:
	var root_link: Link
	var links: Array[Link]
	var switch_state: int = 0:
		set(value):
			if value < links.size():
				switch_state = value

	func _to_string() -> String:
		return "{root_link: %s, links: %s}" % [ root_link, links ]

	func route_from(inbound_segment: Segment) -> Segment:
		if !root_link || links.size() < 1:
			return null
		if root_link.segment == inbound_segment:
			return links[switch_state].segment
		else:
			return root_link.segment

	func points_transform() -> Transform3D:
		var t = Transform3D.IDENTITY
		if !root_link:
			return t
		if root_link.side == Segment.Side.Begin:
			t.origin = root_link.segment.to_global(root_link.segment.curve.get_point_position(0))
		else:
			t.origin = root_link.segment.to_global(root_link.segment.curve.get_point_position(root_link.segment.curve.point_count - 1))
		t = t.rotated_local(Vector3.UP, Vector3.FORWARD.angle_to(root_link.segment.to_global(root_link.direction())))
		return t

@onready var points_overlay_scene: PackedScene = load("res://map/PointsOverlay.tscn")

var platform_segments: Array[PlatformSegment]
var entrance_segments: Array[EntranceSegment]
var exit_segments: Array[ExitSegment]

# Dictionary[Vector3i, PathNode]
var graph: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if !(child is Segment):
			continue
		var segment: Segment = child

		if segment is PlatformSegment:
			platform_segments.append(segment as PlatformSegment)
		if segment is EntranceSegment:
			entrance_segments.append(segment as EntranceSegment)
		if segment is ExitSegment:
			exit_segments.append(segment as ExitSegment)

		if segment.curve.point_count < 2:
			continue

		var curve = segment.curve
		var begin_pos: = Vector3i(segment.to_global(curve.get_point_position(0)).round())
		var end_pos: = Vector3i(segment.to_global(curve.get_point_position(curve.point_count - 1)).round())

		var node1 = graph.get(begin_pos, PathNode.new())
		var node2 = graph.get(end_pos, PathNode.new())

		node1.links.append(Link.new(segment, Segment.Side.Begin, node2))
		node2.links.append(Link.new(segment, Segment.Side.End, node1))

		graph[begin_pos] = node1
		graph[end_pos] = node2

		segment.begin_node = node1
		segment.end_node = node2

	for child in get_children():
		if !(child is Segment):
			continue
		var segment: Segment = child

		if (
			segment.begin_node
			&& segment.begin_node.links.size() > 1
			&& segment.begin_semaphore.is_empty()
		):
			segment.begin_signal_clear = true
			segment.begin_signal_always_clear = true

		if (
			segment.end_node
			&& segment.end_node.links.size() > 1
			&& segment.end_semaphore.is_empty()
		):
			segment.end_signal_clear = true
			segment.end_signal_always_clear = true

		if !segment.begin_semaphore.is_empty():
			segment.get_node(segment.begin_semaphore).clear.connect(func():
				try_clear_signal(segment, Segment.Side.Begin))
		if !segment.end_semaphore.is_empty():
			segment.get_node(segment.end_semaphore).clear.connect(func():
				try_clear_signal(segment, Segment.Side.End))

	for node in graph.values() as Array[PathNode]:
		if node.links.size() <= 2:
			node.root_link = node.links.pop_front()
		else:
			var dir0: = node.links[0].direction()
			var dir1: = node.links[1].direction()
			var dir2: = node.links[2].direction()
			if dir0.dot(dir1) > 0.0:
				node.root_link = node.links[2]
				node.links.remove_at(2)
			elif dir0.dot(dir2) > 0.0:
				node.root_link = node.links[1]
				node.links.remove_at(1)
			else:
				node.root_link = node.links.pop_front()

			var points_overlay: = points_overlay_scene.instantiate()
			points_overlay.path_node = node
			add_child(points_overlay)
			points_overlay.global_transform = node.points_transform()

func try_clear_signal(segment: Segment, side: Segment.Side) -> void:
	if (
		(side == Segment.Side.Begin && segment.begin_signal_clear)
		|| (segment.end_signal_clear)
	):
		return

	var route: Array[Segment] = []
	var dest: = segment.find_route_dest(side, route)
	if !dest:
		return

	for step in route:
		step.occupied = true
		for crossing in step.crossing_segments:
			if !crossing.is_empty():
				step.get_node(crossing).occupied = true

	if side == Segment.Side.Begin:
		segment.begin_signal_clear = true
	else:
		segment.end_signal_clear = true

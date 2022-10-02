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

	func _to_string() -> String:
		return "{root_link: %s, links: %s}" % [ root_link, links ]

	func route_from(inbound_segment: Segment) -> Segment:
		if !root_link || links.size() < 1:
			return null
		if root_link.segment == inbound_segment:
			return links[0].segment
		else:
			return root_link.segment

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

extends Node3D

enum PathSide {
	Begin,
	End,
}

class Link:
	var segment: Segment
	var side: PathSide
	var other_node: PathNode

	func _init(segment: Segment, side: PathSide, other_node: PathNode):
		self.segment = segment
		self.side = side
		self.other_node = other_node

	func _to_string() -> String:
		return "{segment: %d, side: %s, other_node: %d}" % [
			segment.get_instance_id(),
			side_str(),
			other_node.get_instance_id()
		]

	func side_str() -> String:
		match side:
			PathSide.Begin: return "Begin"
			PathSide.End: return "End"
			_: return "Unknown"

	func direction() -> Vector3:
		if side == PathSide.Begin:
			return (segment.curve.get_point_out(0) - segment.curve.get_point_position(0)).normalized()
		else:
			var idx: = segment.curve.point_count - 1
			return (segment.curve.get_point_in(idx) - segment.curve.get_point_position(idx)).normalized()

class PathNode:
	var root_link: Link
	var links: Array[Link]

	func _to_string() -> String:
		return "{root_link: %s, links: %s}" % [ root_link, links ]

@export var platform_segments: Array[NodePath]
@export var entry_segments: Array[NodePath]
@export var exit_segments: Array[NodePath]

var graph: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if !(child is Segment):
			continue
		var segment: Segment = child

		if segment.curve.point_count < 2:
			continue

		var curve = segment.curve
		var begin_pos: = Vector3i(curve.get_point_position(0).round())
		var end_pos: = Vector3i(curve.get_point_position(curve.point_count - 1).round())

		var node1 = graph.get(begin_pos, PathNode.new())
		var node2 = graph.get(end_pos, PathNode.new())

		node1.links.append(Link.new(segment, PathSide.Begin, node2))
		node2.links.append(Link.new(segment, PathSide.End, node1))

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

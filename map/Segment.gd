class_name Segment
extends Path3D

enum Side {
	Begin,
	End,
}

@export_node_path(TrackSemaphore) var begin_semaphore: NodePath
@export_node_path(TrackSemaphore) var end_semaphore: NodePath

var begin_node
var end_node

var begin_signal_clear: bool = false
var begin_signal_always_clear: bool = false
var end_signal_clear: bool = false
var end_signal_always_clear: bool = false

func _ready() -> void:
	if begin_semaphore:
		get_node(begin_semaphore).clear.connect(func(): self.begin_signal_clear = true)
	if end_semaphore:
		get_node(end_semaphore).clear.connect(func(): self.end_signal_clear = true)

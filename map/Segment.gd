class_name Segment
extends Path3D

enum Side {
	Begin,
	End,
}

var begin_node
var end_node

var begin_signal_clear: bool = false
var end_signal_clear: bool = false

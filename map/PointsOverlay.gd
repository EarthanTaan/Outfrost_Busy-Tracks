extends Node3D

@onready var indicator_mat_inactive: Material = load("res://material/points_indicator_inactive.tres")
@onready var indicator_mat_hover: Material = load("res://material/points_indicator_hover.tres")
@onready var indicator_mat_active: Material = load("res://material/points_indicator_active.tres")

@onready var area: Area3D = $Area3d
@onready var indicator1: MeshInstance3D = $Indicator1
@onready var indicator2: MeshInstance3D = $Indicator2
@onready var indicator3: MeshInstance3D = $Indicator3

var path_node:
	set(node):
		if path_node != null:
			path_node.locked.disconnect(on_switch_locked)

		path_node = node
		node.locked.connect(on_switch_locked)

		link_idx.clear()
		if node.links.size() < 2:
			return
		var dir0_90: Vector3 = node.links[0].direction().rotated(Vector3.UP, TAU * 0.25)
		var dir1: Vector3 = node.links[1].direction()
		if dir0_90.dot(dir1) < 0.0:
			link_idx[0] = 0
			link_idx[1] = 1
		else:
			link_idx[0] = 1
			link_idx[1] = 0
		init_materials()

var link_idx: = {}

func _ready() -> void:
	area.input_event.connect(func(_c, event: InputEvent, _p, _n, _s):
		if event.is_action_pressed("click"):
			switch())
	init_materials()

func on_switch_locked(locked: bool) -> void:
	if locked:
		if path_node.switch_state == link_idx[0]:
			indicator3.hide()
		else:
			indicator2.hide()
	else:
		indicator2.show()
		indicator3.show()

func switch() -> void:
	if !path_node || path_node.switch_locked:
		return
	if path_node.switch_state == link_idx[0]:
		path_node.switch_state = link_idx[1]
		indicator2.material_override = indicator_mat_inactive
		indicator3.material_override = indicator_mat_active
	else:
		path_node.switch_state = link_idx[0]
		indicator2.material_override = indicator_mat_active
		indicator3.material_override = indicator_mat_inactive

func init_materials() -> void:
	if !path_node || !indicator1:
		return
	indicator1.material_override = indicator_mat_active
	if path_node.switch_state == link_idx[0]:
		indicator2.material_override = indicator_mat_active
		indicator3.material_override = indicator_mat_inactive
	else:
		indicator2.material_override = indicator_mat_inactive
		indicator3.material_override = indicator_mat_active

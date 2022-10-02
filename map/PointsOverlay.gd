extends Node3D

@onready var indicator_mat_inactive: Material = load("res://material/points_indicator_inactive.tres")
@onready var indicator_mat_hover: Material = load("res://material/points_indicator_hover.tres")
@onready var indicator_mat_active: Material = load("res://material/points_indicator_active.tres")

@onready var area_left: Area3D = $Area2
@onready var area_right: Area3D = $Area3
@onready var indicator1: MeshInstance3D = $Indicator1
@onready var indicator2: MeshInstance3D = $Indicator2
@onready var indicator3: MeshInstance3D = $Indicator3

var path_node

func _ready() -> void:
	area_left.input_event.connect(func(_c, event: InputEvent, _p, _n, _s):
		if event.is_action_pressed("click"):
			switch_left())
	area_right.input_event.connect(func(_c, event: InputEvent, _p, _n, _s):
		if event.is_action_pressed("click"):
			switch_right())
	indicator1.material_override = indicator_mat_active
	indicator2.material_override = indicator_mat_active
	indicator3.material_override = indicator_mat_inactive

func switch_left() -> void:
	indicator2.material_override = indicator_mat_active
	indicator3.material_override = indicator_mat_inactive

func switch_right() -> void:
	indicator2.material_override = indicator_mat_inactive
	indicator3.material_override = indicator_mat_active

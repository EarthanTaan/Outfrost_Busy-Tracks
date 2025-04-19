extends Node3D

@export_node_path("MeshInstance3D") var mesh_instance_path: NodePath

@onready var mesh_instance: MeshInstance3D = get_node(mesh_instance_path)
var train: Train

var materials: Array[StandardMaterial3D] = []
var lights_on: bool = false

func _ready() -> void:
	var node = get_parent()
	while !(node is Train) && node != get_tree().root:
		node = node.get_parent()
	if !(node is Train):
		push_error("failed to initialize: parent of type Train not found")
		return
	train = node

	for slot in range(mesh_instance.get_surface_override_material_count()):
		var mat: = mesh_instance.get_surface_override_material(slot).duplicate()
		mesh_instance.set_surface_override_material(slot, mat)
		materials.append(mat)

	lights_on = train.interior_lighting_on
	for mat in materials:
		mat.emission_enabled = lights_on

func _process(delta: float) -> void:
	if !train:
		return

	if train.interior_lighting_on != lights_on:
		lights_on = train.interior_lighting_on
		for mat in materials:
			mat.emission_enabled = lights_on

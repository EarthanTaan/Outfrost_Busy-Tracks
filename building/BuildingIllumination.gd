extends Node3D

const NIGHT_LIGHT_THRESHOLD_START: float = 0.3
const NIGHT_LIGHT_THRESHOLD_END: float = 0.65

@export_node_path("MeshInstance3D") var mesh_instance_path: NodePath

@onready var mesh_instance: MeshInstance3D = get_node(mesh_instance_path)
@onready var lighting_threshold: float = randf_range(
	NIGHT_LIGHT_THRESHOLD_START,
	NIGHT_LIGHT_THRESHOLD_END)

var materials: Array[StandardMaterial3D] = []
var light_sources: Array[Light3D] = []
var lights_on: bool = false

func _ready() -> void:
	for slot in range(mesh_instance.get_surface_override_material_count()):
		var mat: = mesh_instance.get_surface_override_material(slot).duplicate()
		mesh_instance.set_surface_override_material(slot, mat)
		if mat.emission_enabled:
			materials.append(mat)

	for mat in materials:
		mat.emission_enabled = lights_on

	for child in get_children():
		if child is Light3D:
			light_sources.append(child)

	for light in light_sources:
		light.visible = lights_on

func _process(delta: float) -> void:
	var on: = Daytime.night_light > lighting_threshold
	if on != lights_on:
		lights_on = on
		for mat in materials:
			mat.emission_enabled = lights_on
		for light in light_sources:
			light.visible = lights_on

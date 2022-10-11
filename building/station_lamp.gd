extends Node3D

const NIGHT_LIGHT_THRESHOLD: float = 0.25

@export var range: float = 16.0

func _process(delta: float) -> void:
	var on: = Daytime.night_light > NIGHT_LIGHT_THRESHOLD
	%OmniLight.visible = on
	%OmniLight.omni_range = range

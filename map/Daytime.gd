extends Node

var day_light: float = 0.0
var night_light: float = 1.0

func set_time(time: float) -> void:
	var day_perc = 1.0 - (abs(time - 0.5) * 2.0)
	day_light = clampf(remap(day_perc, 0.35, 0.65, 0.0, 1.0), 0.0, 1.0)
	night_light = clampf(remap(day_perc, 0.45, 0.35, 0.0, 1.0), 0.0, 1.0)

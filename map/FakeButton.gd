extends ColorRect

signal released()

func _ready() -> void:
	mouse_entered.connect(func():
		var c: = color
		c.a = 1.0
		color = c)
	mouse_exited.connect(func():
		var c: = color
		c.a = 0.0
		color = c)

func _input(event: InputEvent) -> void:
	if !(event is InputEventMouseButton):
		return

	var mouse_event: = event as InputEventMouseButton
	if (
		mouse_event.button_index == 1
		&& !mouse_event.is_pressed()
		&& get_global_rect().has_point(mouse_event.position)
	):
		released.emit()
		get_tree().root.set_input_as_handled()

func reset() -> void:
	var c: = color
	c.a = 0.0
	color = c

class_name TrackSemaphore
extends Node3D

signal clear()

@onready var ui: Control = $SemaphoreUi

func _ready() -> void:
	$Area3d.input_event.connect(on_area_input_event)
	$SemaphoreUi/Control/Panel/FakeButton.released.connect(on_button_released)

func _input(event: InputEvent) -> void:
	if !(event is InputEventMouseButton):
		return

	var mouse_event: = event as InputEventMouseButton
	if (
		ui.visible
		&& mouse_event.button_index == 1
		&& !mouse_event.is_pressed()
	):
		ui.hide()
		get_tree().root.set_input_as_handled()

func on_area_input_event(camera: Node, event: InputEvent, position: Vector3, _normal, _shape_idx) -> void:
	if event.is_action_pressed("click"):
		# open UI
		var ui_pos: = (camera as Camera3D).unproject_position(position)
		ui_pos = ui_pos.clamp(Vector2(100.0, 160.0), Vector2(get_viewport().size) - Vector2(100.0, 0.0))
		ui.position = ui_pos
		$SemaphoreUi/Control/Panel/FakeButton.reset()
		ui.show()

func on_button_released() -> void:
	clear.emit()
	ui.hide()

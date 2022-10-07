class_name Game
extends Node

@onready var main_menu: Control = $UI/MainMenu
@onready var transition_screen: TransitionScreen = $UI/TransitionScreen
@onready var stopwatch_panel: Panel = $UI/StopwatchPanel
@onready var stopwatch_label: Label = $UI/StopwatchPanel/StopwatchLabel
@onready var stopwatch_blink: Timer = $UI/StopwatchPanel/BlinkTimer
@onready var count_panel: Panel = $UI/CountPanel
@onready var count_label: Label = $UI/CountPanel/CountLabel
@onready var map: = $Map

var debug: RefCounted
var is_running: bool = false

func _ready() -> void:
	if OS.has_feature("debug") && FileAccess.file_exists("res://debug.gd"):
		var debug_script: GDScript = load("res://debug.gd")
		if debug_script:
			debug = debug_script.new(self)
			debug.startup()

	stopwatch_panel.hide()
	count_panel.hide()
	stopwatch_blink.timeout.connect(func(): stopwatch_label.visible = !stopwatch_label.visible)

	main_menu.start_game.connect(on_start_game)
	main_menu.speedrun_mode.connect(on_speedrun_mode)
	map.game_finished.connect(on_game_finished)

func _process(delta: float) -> void:
	DebugOverlay.display("fps %d" % Performance.get_monitor(Performance.TIME_FPS))

	stopwatch_label.text = "%02d:%02d.%03d" % [
		int(map.stopwatch) / 60,
		int(map.stopwatch) % 60,
		int((map.stopwatch - floorf(map.stopwatch)) * 1000.0),
	]

	count_label.text = "%02d/%02d" % [
		map.trains_dispatched,
		map.SPAWN_INTERVALS.size() + 1
	]

	if Input.is_action_just_pressed("menu"):
		back_to_menu()

func on_start_game() -> void:
	is_running = true
	map.reset()
	main_menu.hide()

func on_speedrun_mode() -> void:
	on_start_game()
	stopwatch_panel.show()
	count_panel.show()

func back_to_menu() -> void:
	is_running = false
	stopwatch_blink.stop()
	stopwatch_label.show()
	stopwatch_panel.hide()
	count_panel.hide()
	main_menu.show()

func on_game_finished() -> void:
	stopwatch_blink.start()

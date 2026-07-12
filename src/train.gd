extends Node2D

@export var debug_force_show: bool = false
@export var speed: float = 90.0

# Ajust the train on to the tracks
@export_range(0.0, 1.0, 0.001) var track_y_ratio: float = 0.0
@export var track_y_offset: float = 35.0

var moving: bool = false
var start_position: Vector2
var trigger_time: float = 12.0
var has_triggered: bool = false


func _ready() -> void:
	start_position = position

	_update_vertical_position()
	get_viewport().size_changed.connect(_update_vertical_position)

	reset()
	$Animated_Train.play("Train_moving")

	if debug_force_show:
		show_train()
		start_moving()


func _update_vertical_position() -> void:
	var viewport_height := get_viewport_rect().size.y
	var new_y := viewport_height * track_y_ratio + track_y_offset

	start_position.y = new_y
	position.y = new_y


func reset() -> void:
	position = start_position
	moving = false
	visible = false
	has_triggered = false

	if has_node("Animated_Train"):
		$Animated_Train.play("Train_moving")


func show_train() -> void:
	visible = true


func start_moving() -> void:
	moving = true
	visible = true


func _process(delta: float) -> void:
	if not has_triggered and not debug_force_show:
		var timer_panel = get_tree().current_scene.get_node("UI/Timer_Panel")

		if timer_panel.time_remaining <= trigger_time and timer_panel.is_running:
			has_triggered = true
			show_train()
			start_moving()

	if moving:
		position.x += speed * delta

		var screen_width := get_viewport_rect().size.x
		if position.x > screen_width + 400:
			moving = false
			visible = false

extends Control

@onready var time_label: Label = $Time_Label

var time_remaining: float = 0.0
var is_running: bool = false
var danger_threshold: float = 11.0

const NORMAL_COLOR = Color(0.05, 0.05, 0.05)
const DANGER_COLOR = Color(0.8, 0.1, 0.1)

func start_countdown(seconds: float):
	time_remaining = seconds + 1
	is_running = true
	time_label.modulate = NORMAL_COLOR
	update_label()

func _process(delta):
	if not is_running:
		return
	
	time_remaining -= delta
	
	if time_remaining <= 0:
		time_remaining = 0
		is_running = false
		update_label()
		_on_time_expired()
		return
	
	update_label()
	
	if time_remaining <= danger_threshold:
		_apply_danger_effect()
	else:
		time_label.modulate = NORMAL_COLOR
		time_label.position = Vector2.ZERO

func update_label():
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

func _apply_danger_effect():
	time_label.modulate = DANGER_COLOR
	var shake_amount = 2.0
	time_label.position = Vector2(
		randf_range(-shake_amount, shake_amount),
		randf_range(-shake_amount, shake_amount)
	)

func _on_time_expired():
	var train = get_tree().current_scene.get_node("Train")
	train.show_train()
	train.start_moving()

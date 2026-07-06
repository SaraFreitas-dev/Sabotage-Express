extends Control

@onready var time_label: Label = $Time_Label
@onready var plank_sprite: Sprite2D = $Plank_Sprite
@onready var train_sound: AudioStreamPlayer2D = $"../../Train_Sounds"

var time_remaining: float = 0.0
var is_running: bool = false
var danger_threshold: float = 16.0
var danger_active: bool = false

const TIMER_LABEL_POSITION := Vector2(155, 180)
const TIMER_LABEL_SIZE := Vector2(1, 1)
const PLANK_BASE_POSITION := Vector2.ZERO 

const NORMAL_COLOR = Color(0.05, 0.05, 0.05)
const DANGER_COLOR = Color(0.8, 0.1, 0.1)



func _ready() -> void:
	setup_label()

 
func setup_label() -> void:
	time_label.position = TIMER_LABEL_POSITION
	time_label.size = TIMER_LABEL_SIZE
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func start_countdown(seconds: float):
	time_remaining = seconds + 1
	is_running = true
	danger_active = false
	time_label.modulate = NORMAL_COLOR
	time_label.position = TIMER_LABEL_POSITION
	plank_sprite.position = PLANK_BASE_POSITION
	update_label()
	var train = get_tree().current_scene.get_node("Train")
	train.reset()

func _process(delta):
	if not is_running:
		return

	
	time_remaining -= delta
	
	if time_remaining <= 0:
		time_remaining = 0
		is_running = false
		update_label()
		time_label.position = TIMER_LABEL_POSITION
		plank_sprite.position = PLANK_BASE_POSITION
		train_sound.stop()
		_on_time_expired()
		return
	
	update_label()
	
	if time_remaining <= danger_threshold:
		if not danger_active:
			danger_active = true
			train_sound.play()  # Plays once
		_apply_danger_effect()
	else:
		time_label.modulate = NORMAL_COLOR
		time_label.position = TIMER_LABEL_POSITION
		plank_sprite.position = PLANK_BASE_POSITION

func update_label():
	var total_seconds := int(time_remaining)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

func _apply_danger_effect():
	time_label.modulate = DANGER_COLOR
	
	var shake_amount = 2.0
	var shake_offset = Vector2(
		randf_range(-shake_amount, shake_amount),
		randf_range(-shake_amount, shake_amount)
	)
	
	time_label.position = TIMER_LABEL_POSITION + shake_offset
	plank_sprite.position = PLANK_BASE_POSITION + shake_offset * 0.2  # shake smaller than the text


func _on_time_expired() -> void:
	print("TIME EXPIRED")

	var level := get_tree().current_scene

	var train = level.get_node("Train")
	train.show_train()
	train.start_moving()

	if level.has_node("LoseSequence"):
		print("LoseSequence found")
		level.get_node("LoseSequence").play_lose()
	else:
		print("LoseSequence NOT found")

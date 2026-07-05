extends Node2D

@export var debug_force_show: bool = false
@export var speed: float = 80.0
var moving: bool = false
var start_position: Vector2
var trigger_time: float = 12.0
var has_triggered: bool = false
var has_lost: bool = false

func _ready():
	start_position = position
	reset()
	$Animated_Train.play("Train_moving")
	
	if debug_force_show:
		show_train()
		start_moving()

func reset():
	position = start_position
	moving = false
	visible = false
	has_triggered = false
	has_lost = false
	if has_node("Animated_Train"):
		$Animated_Train.play("Train_moving")

func show_train():
	visible = true

func start_moving():
	moving = true
	visible = true

func _process(delta):
	if not has_triggered and not debug_force_show:
		var timer_panel = get_tree().current_scene.get_node("UI/Timer_Panel")
		if timer_panel.time_remaining <= trigger_time and timer_panel.is_running:
			has_triggered = true
			show_train()
			start_moving()
	
	if moving:
		position.x += speed * delta
		
		var screen_width = get_viewport_rect().size.x
		if position.x > screen_width + 400:
			moving = false
			visible = false
			if not has_lost:
				has_lost = true
				var lose_sequence = get_tree().current_scene.get_node_or_null("LoseSequence")
				if lose_sequence:
					lose_sequence.play_lose()

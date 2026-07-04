extends Node2D

@export var debug_force_show: bool = false
@export var speed: float = 100.0 

var moving: bool = false

func _ready():
	visible = false
	$Animated_Train.play("Train_moving")
	
	if debug_force_show:
		show_train()
		start_moving()

func show_train():
	visible = true

func start_moving():
	moving = true

func _process(delta):
	if moving:
		position.x += speed * delta
		
		# To remove the train
		var screen_width = get_viewport_rect().size.x
		if position.x > screen_width + 400:  # safety margin
			moving = false
			queue_free()

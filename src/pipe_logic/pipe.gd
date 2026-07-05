extends Area2D
class_name Pipe

signal pipe_rotated
signal drag_started(piece: Pipe)
signal drag_ended(piece: Pipe)

@export var connections: Array = [false, false, false, false]
@export var type: int = 0
@onready var sprite: Sprite2D = $Sprite2D

var is_fixed: bool = false

func rotate_pipe_clockwise() -> void:
	if connections == [true, true, true, true]:
		return
		
	var is_straight_horizontal = (connections == [false, true, false, true])
	var is_straight_vertical = (connections == [true, false, true, false])
	
	if is_straight_horizontal or is_straight_vertical:
		if is_straight_horizontal:
			connections = [true, false, true, false]
			rotation_degrees = 90.0
		else:
			connections = [false, true, false, true]
			rotation_degrees = 0.0
		pipe_rotated.emit()
		return
		
	var last = connections[3]
	connections[3] = connections[2]
	connections[2] = connections[1]
	connections[1] = connections[0]
	connections[0] = last
	rotation_degrees += 90.0
	pipe_rotated.emit()

func set_pipe_data(new_texture: Texture2D, new_connections: Array) -> void:
	if sprite != null:
		sprite.texture = new_texture
	connections = new_connections

func randomize_rotation() -> void:
	var is_straight = (connections == [false, true, false, true] or connections == [true, false, true, false])
	var is_cross = (connections == [true, true, true, true])
	
	if is_cross:
		return
	elif is_straight:
		var random_turns = randi() % 2 
		if random_turns == 1:
			connections = [true, false, true, false]
			rotation_degrees = 90.0
		else:
			connections = [false, true, false, true]
			rotation_degrees = 0.0
	else:
		var random_turns = randi() % 4
		for i in range(random_turns):
			var last = connections[3]
			connections[3] = connections[2]
			connections[2] = connections[1]
			connections[1] = connections[0]
			connections[0] = last
			rotation_degrees += 90.0

func _on_input_event(viewport, event, shape_idx):
	# Se a peça for fixa, ela não aceita cliques de mouse
	if is_fixed: 
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			rotate_pipe_clockwise()

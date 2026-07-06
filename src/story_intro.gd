extends Node2D

@onready var narration: AudioStreamPlayer = $Narration
@onready var background: TextureRect = $Background 
@onready var music_bg: AudioStreamPlayer = $Music_BG 

func _ready() -> void:
	background.position = Vector2(0, 0)
	background.size = Vector2(1280, 720)
	narration.play()
	music_bg.play()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		narration.stop()
		get_tree().change_scene_to_file("res://src/level_base.tscn")

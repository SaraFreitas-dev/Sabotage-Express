extends CanvasLayer

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var lose_popup = $LosePopup


func _ready() -> void:
	layer = 100

	video_player.visible = false
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.finished.connect(_on_video_finished)

	lose_popup.visible = false


func play_lose() -> void:
	lose_popup.visible = false

	# Hide the gameplay elements, same as the win/explosion sequence does.
	var level := get_tree().current_scene
	if level.has_node("Tiles_grid"):
		level.get_node("Tiles_grid").visible = false
	if level.has_node("Cable_Panel"):
		level.get_node("Cable_Panel").visible = false
	if level.has_node("Honey_Badger"):
		level.get_node("Honey_Badger").visible = false
	if level.has_node("Dynamite"):
		level.get_node("Dynamite").visible = false
	if level.has_node("UI/Buttons_container"):
		level.get_node("UI/Buttons_container").visible = false
	if level.has_node("UI/Timer_Panel"):
		level.get_node("UI/Timer_Panel").visible = false
	if level.has_node("Train_Sounds"):
		level.get_node("Train_Sounds").stop()

	video_player.visible = true
	video_player.play()


func _on_video_finished() -> void:
	video_player.visible = false
	video_player.stop()
	lose_popup.visible = true
	lose_popup.show_popup()
	get_tree().paused = true

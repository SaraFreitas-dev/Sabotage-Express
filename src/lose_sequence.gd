extends CanvasLayer

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var lose_popup = $LosePopup


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	video_player.process_mode = Node.PROCESS_MODE_ALWAYS
	video_player.visible = false

	video_player.anchor_left = 0.0
	video_player.anchor_top = 0.0
	video_player.anchor_right = 1.0
	video_player.anchor_bottom = 1.0
	video_player.offset_left = 0.0
	video_player.offset_top = 0.0
	video_player.offset_right = 0.0
	video_player.offset_bottom = 0.0
	video_player.expand = true
	video_player.z_index = 1000

	video_player.finished.connect(_on_video_finished)

	lose_popup.process_mode = Node.PROCESS_MODE_ALWAYS
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
	print("LOSE VIDEO FINISHED")

	video_player.visible = false
	video_player.stop()

	lose_popup.visible = true
	lose_popup.show_popup()

	print("LosePopup visible: ", lose_popup.visible)
	print("LosePopup position: ", lose_popup.global_position)
	print("LosePopup scale: ", lose_popup.scale)

	#get_tree().paused = true

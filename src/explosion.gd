extends Node2D

signal explosion_finished

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion_sound: AudioStreamPlayer = $Explosion_Sound
@onready var win_popup: Sprite2D = $WinPopup


func _ready() -> void:
	visible = false
	
	top_level = true
	z_as_relative = false
	z_index = 90
	
	anim.z_as_relative = false
	anim.z_index = 91
	
	win_popup.visible = false
	win_popup.top_level = true
	win_popup.z_as_relative = false
	win_popup.z_index = 100
	
	anim.sprite_frames.set_animation_loop("explosion", false)
	anim.animation_finished.connect(_on_animation_finished)
	
func _process(delta):
	if Input.is_action_just_pressed("e"): # SO PARA TESTE - remover depois
		var dynamite = get_tree().current_scene.get_node("Dynamite")
		play_explosion(dynamite.global_position)


func _on_animation_finished(): 
	explosion_finished.emit()


func play_explosion(start_position: Vector2) -> void:
	var screen_center = get_viewport_rect().size / 2.0
	
	global_position = screen_center
	scale = Vector2(0.25, 0.25)
	visible = true
	
	win_popup.visible = false
	
	explosion_sound.stop()
	explosion_sound.play()
	anim.visible = true
	anim.play("explosion")
	
	var level = get_tree().current_scene
	level.get_node("Tiles_grid").visible = false
	level.get_node("Cable_Panel").visible = false
	level.get_node("Honey_Badger").visible = false
	level.get_node("Dynamite").visible = false
	level.get_node("UI/Buttons_container").visible = false
	level.get_node("UI/Timer_Panel").visible = false
	level.get_node("Train").visible = false
	level.get_node("Train_Sounds").stop()
	
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(4.5, 4.5), 0.55)
	await tween.finished
	
	win_popup.show_popup()
	get_tree().paused = true  # <- Stops everything: _process, animações, timers

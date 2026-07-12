extends TextureButton

@onready var music_player: AudioStreamPlayer2D = $"../../../Music_Player"
@onready var train_sounds: AudioStreamPlayer2D = $"../../../Train_Sounds"

func _ready():
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	music_player.finished.connect(_on_music_finished)
	music_player.play()

# Play in LOOP
func _on_music_finished():
	music_player.play()

func _on_pressed():
	if music_player.playing and not music_player.stream_paused:
		music_player.stream_paused = true
		train_sounds.stream_paused = true
	else:
		music_player.stream_paused = false
		train_sounds.stream_paused = false
		if not music_player.playing:
			music_player.play()

func _on_hover():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.08)

func _on_unhover():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.15)

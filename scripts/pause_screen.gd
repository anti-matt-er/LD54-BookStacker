extends "res://scripts/simple_fade.gd"


const PAUSE_TRANSITION := 0.5
const MUSIC_DIM := -10.0

@onready var game := get_parent()

var paused := false


func _process(_delta) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()


func toggle_pause(skip_blur: bool = false) -> void:
	if !game.started:
		return
		
	paused = !paused
	get_tree().paused = paused
	
	if paused:
		game.music.volume_db = MUSIC_DIM
	else:
		game.music.volume_db = 0.0
	
	game.menu_enabled.emit(paused)
	
	animate(float(paused), PAUSE_TRANSITION)
	if !skip_blur:
		game.blur.animate(float(paused), PAUSE_TRANSITION)

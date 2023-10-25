extends TextButton


func _ready() -> void:
	super()
	await get_tree().process_frame
	await get_tree().process_frame
	update_text()


func action() -> void:
	game.toggle_fullscreen()
	await get_tree().process_frame
	update_text()


func update_text() -> void:
	text = "On" if game.fullscreen else "Off"

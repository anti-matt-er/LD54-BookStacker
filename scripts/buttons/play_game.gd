extends TextButton


@onready var game := find_parent("Game")


func action() -> void:
	game.start()

extends TextButton


@onready var main_screen := find_parent("Main")
@onready var options_screen := main_screen.get_parent().get_node("Options")


func action() -> void:
	main_screen.hide()
	options_screen.show()

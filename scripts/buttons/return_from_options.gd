extends TextButton


@onready var options_screen := find_parent("Options")
@onready var main_screen := options_screen.get_parent().get_node("Main")


func action() -> void:
	options_screen.hide()
	main_screen.show()

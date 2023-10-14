extends Node


@onready var viewport_size := Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height")
)
@onready var vu := 1.0 / viewport_size.length()

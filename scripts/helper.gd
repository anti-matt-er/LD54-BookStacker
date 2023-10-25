extends Node


@onready var viewport_size := Vector2(
	ProjectSettings.get_setting("display/window/size/window_width_override"),
	ProjectSettings.get_setting("display/window/size/window_height_override")
)
@onready var vu := 1.0 / viewport_size.length()

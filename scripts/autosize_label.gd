extends Label
class_name AutosizeLabel


const MIN_SIZE := 22

@onready var base_size := label_settings.font_size


func _ready() -> void:
	resize()
	get_viewport().size_changed.connect(resize)


func resize() -> void:
	label_settings.font_size = maxi(MIN_SIZE, roundi(base_size * get_viewport_rect().size.length() * Helper.vu))

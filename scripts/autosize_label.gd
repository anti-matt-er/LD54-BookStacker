extends Label
class_name AutosizeLabel


const MIN_SIZE := 22

@export var scale_factor := 0.035


func _ready() -> void:
	resize()
	get_viewport().size_changed.connect(resize)


func resize() -> void:
	label_settings.font_size = maxi(MIN_SIZE, roundi(sqrt(get_viewport_rect().get_area()) * scale_factor))

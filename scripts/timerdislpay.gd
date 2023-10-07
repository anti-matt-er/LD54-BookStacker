extends Label


const scale_factor := 0.035
const min_size := 22


func _ready() -> void:
	resize()
	get_viewport().size_changed.connect(resize)


func resize() -> void:
	label_settings.font_size = maxi(min_size, roundi(sqrt(get_viewport_rect().get_area()) * scale_factor))

extends Label


const SCALE_FACTOR := 0.035
const MIN_SIZE := 22
const NORMAL_COLOR := Color("9affcd")
const LOW_COLOR := Color("ff5143")


func _ready() -> void:
	resize()
	get_viewport().size_changed.connect(resize)


func resize() -> void:
	label_settings.font_size = maxi(MIN_SIZE, roundi(sqrt(get_viewport_rect().get_area()) * SCALE_FACTOR))


func set_low(state: bool) -> void:
	if state:
		label_settings.font_color = LOW_COLOR
	else:
		label_settings.font_color = NORMAL_COLOR

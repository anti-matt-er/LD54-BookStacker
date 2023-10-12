extends AutosizeLabel


const NORMAL_COLOR := Color.WHITE
const LOW_COLOR := Color("ff5143")


func set_low(state: bool) -> void:
	if state:
		label_settings.font_color = LOW_COLOR
		label_settings.outline_color = LOW_COLOR
	else:
		label_settings.font_color = NORMAL_COLOR
		label_settings.font_color = NORMAL_COLOR

extends MarginContainer


var onscreen := false
var tween: Tween

const OFFSCREEN_MARGIN := 110


func animate(on: bool, time: float) -> void:
	if on == onscreen:
		return
	
	onscreen = on
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	
	tween.tween_property(self, "theme_override_constants/margin_bottom", 0 if on else -OFFSCREEN_MARGIN, time)

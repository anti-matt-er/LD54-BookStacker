extends CanvasItem

var tween: Tween


func animate(alpha: float, time: float) -> void:
	var current = modulate.a
	
	if is_equal_approx(current, alpha):
		return
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	
	tween.tween_property(self, "modulate:a", alpha, time)
	
	await tween.finished
	
	visible = !is_zero_approx(alpha)

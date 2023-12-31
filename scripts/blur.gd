extends ColorRect


@onready var shader: ShaderMaterial = material

var tween: Tween


func animate(blur: float, time: float) -> void:
	var current = shader.get_shader_parameter("blur")
	
	if is_equal_approx(current, blur):
		return
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	
	tween.tween_method(set_blur, current, blur, time)
	
	await tween.finished
	
	# Waiting on https://github.com/godotengine/godot/issues/83939
	#visible = !is_zero_approx(blur)


func set_blur(amount: float) -> void:
	shader.set_shader_parameter("blur", amount)
 

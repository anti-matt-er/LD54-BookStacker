extends TextureRect


const FADE_TIME := 0.25
const INACTIVE_OPACITY := 0.75

@export var active := false

var tween: Tween

signal clicked


func _ready() -> void:
	if active:
		modulate.a = INACTIVE_OPACITY
	else:
		modulate.a = 0
	
	mouse_entered.connect(func(): set_hovered(true))
	mouse_exited.connect(func(): set_hovered(false))


func _gui_input(event: InputEvent) -> void:
	if active && event.is_action_pressed("ui_click"):
		clicked.emit()


func set_active(state: bool) -> void:
	active = state
	
	if state:
		tween_opacity(modulate.a, INACTIVE_OPACITY)
	else:
		tween_opacity(modulate.a, 0)


func set_hovered(state: bool) -> void:
	if !active:
		return
	
	if state:
		tween_opacity(modulate.a, 1)
	else:
		tween_opacity(modulate.a, INACTIVE_OPACITY)


func tween_opacity(from: float, to: float) -> void:
	if tween:
		tween.kill()
	
	modulate.a = from
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", to, FADE_TIME)

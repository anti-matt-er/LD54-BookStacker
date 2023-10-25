extends Label
class_name TextButton


const TRANSITION_TIME := 0.2

@export_color_no_alpha var hover_color := Color("f4db71")
@export_color_no_alpha var click_color := Color("c1272d")
@export var hover_scale := 1.25

@onready var game := find_parent("Game")
@onready var sfx := game.get_node("UIClickSFX")
@onready var idle_color := label_settings.font_color

var hovered := false
var tween: Tween


func _ready() -> void:
	await RenderingServer.frame_post_draw
	
	label_settings = label_settings.duplicate()
	pivot_offset = size / 2
	
	mouse_entered.connect(set_hover.bind(true))
	mouse_exited.connect(set_hover.bind(false))
	game.start_screen.menu_enabled.connect(set_enabled)


func set_hover(state: bool) -> void:
	if hovered == state:
		return
	
	hovered = state
	
	if hovered:
		sfx.play()
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_parallel(true)
	
	if hovered:
		tween.tween_property(self, "label_settings:font_color", hover_color, TRANSITION_TIME)
		tween.tween_property(self, "scale", Vector2.ONE * hover_scale, TRANSITION_TIME)
	else:
		tween.tween_property(self, "label_settings:font_color", idle_color, TRANSITION_TIME)
		tween.tween_property(self, "scale", Vector2.ONE, TRANSITION_TIME)


func set_enabled(enabled: bool) -> void:
	mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE


func _gui_input(event: InputEvent) -> void:
	if !hovered:
		return
	
	if event.is_action_pressed("ui_click"):
		if tween:
			tween.kill()
		
		label_settings.font_color = click_color
		scale = Vector2.ONE * hover_scale
		
	if event.is_action_released("ui_click"):
		action()


func _process(_delta: float) -> void:
	if Input.is_action_just_released("ui_click") && (!tween || !tween.is_running()):
		label_settings.font_color = idle_color
		scale = Vector2.ONE


func action() -> void:
	pass

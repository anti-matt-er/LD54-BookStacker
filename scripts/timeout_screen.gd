extends CenterContainer


const TRANSITION_ROTATIONS := 2
const TRANSITION_ROTATION_TIME := 1.0
const TRANSITION_SCALE_TIME := 1.5

@onready var label := $LabelAnchor/Label
@onready var sfx := $SFX

var tween: Tween


func _ready() -> void:
	center_label()
	get_viewport().size_changed.connect(center_label)


func center_label() -> void:
	await RenderingServer.frame_post_draw
	label.pivot_offset = label.size / 2


func transition_in() -> void:
	modulate.a = 1
	sfx.play()
	
	if tween:
		tween.kill()
	
	label.rotation = TRANSITION_ROTATIONS * -TAU
	label.scale = Vector2.ZERO
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_parallel(true)
	tween.tween_property(label, "rotation", 0, TRANSITION_ROTATION_TIME)
	tween.tween_property(label, "scale", Vector2.ONE, TRANSITION_SCALE_TIME)

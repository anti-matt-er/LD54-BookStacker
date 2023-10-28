extends Camera3D


const TRANSITION_TIME := 0.5
const SLOW_PAN_TIME := 2.5

@onready var game := get_parent()
@onready var angles := game.get_node("Camera Angles")
@onready var menu_angle := angles.get_node("Menu")
@onready var idle_angle := angles.get_node("Idle")
@onready var box_angle := angles.get_node("Box")
@onready var complete_angle := angles.get_node("Complete")

var tween


func _ready() -> void:
	await get_tree().process_frame
	
	game.shelf_arrow.clicked.connect(switch_to_idle)
	game.box_arrow.clicked.connect(switch_to_box)


func pan(angle: Marker3D, time: float, trans: Tween.TransitionType) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(trans)
	tween.set_parallel(true)
	tween.tween_property(self, "position", angle.position, time)
	tween.tween_property(self, "rotation", angle.rotation, time)


func switch_angle_to(angle: Marker3D) -> void:
	pan(angle, TRANSITION_TIME, Tween.TRANS_CIRC)


func start() -> void:
	pan(idle_angle, SLOW_PAN_TIME, Tween.TRANS_SINE)


func end() -> void:
	pan(menu_angle, SLOW_PAN_TIME, Tween.TRANS_SINE)


func switch_to_idle() -> void:
	switch_angle_to(idle_angle)
	game.shelf_arrow.set_active(false)
	game.box_arrow.set_active(true)


func switch_to_box() -> void:
	switch_angle_to(box_angle)
	game.shelf_arrow.set_active(true)
	game.box_arrow.set_active(false)


func switch_to_complete() -> void:
	switch_angle_to(complete_angle)
	game.shelf_arrow.set_active(false)
	game.box_arrow.set_active(false)

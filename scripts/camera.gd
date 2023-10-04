extends Camera3D


const TRANSITION_TIME := 0.5

@onready var game := get_parent()
@onready var angles := game.get_node("Camera Angles")
@onready var idle_angle := angles.get_node("Idle")
@onready var box_angle := angles.get_node("Box")
@onready var complete_angle := angles.get_node("Complete")

var tween


func switch_angle_to(angle: Marker3D) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_parallel(true)
	tween.tween_property(self, "position", angle.position, TRANSITION_TIME)
	tween.tween_property(self, "rotation", angle.rotation, TRANSITION_TIME)


func switch_to_idle() -> void:
	switch_angle_to(idle_angle)


func switch_to_box() -> void:
	switch_angle_to(box_angle)


func switch_to_complete() -> void:
	switch_angle_to(complete_angle)

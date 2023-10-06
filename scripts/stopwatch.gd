extends Node3D


@onready var hand := $Hand

var remaining := 0
var total := 0

signal finished


func set_timer(time: int, start: bool = false) -> void:
	assert(time >= 0)
	
	if start:
		total = time
	
	remaining = time
	hand.rotation.y = TAU / total * time
	
	if time == 0:
		finished.emit()
		return
	
	get_tree().create_timer(1).timeout.connect(func(): set_timer(time - 1))

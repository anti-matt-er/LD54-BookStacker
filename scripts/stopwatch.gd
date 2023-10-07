extends Node3D


const LOW_TIME := 30

@onready var hand := $Hand
@onready var ticker := $Ticker
@onready var max_dimension: float = $Watch.get_aabb().get_longest_axis_size()

var remaining := 0
var total := 0
var low := false

signal finished
signal running_out


func set_timer(time: int, start: bool = false) -> void:
	assert(time >= 0)
	
	if start:
		total = time
		low = false
	
	remaining = time
	hand.rotation.y = TAU / total * time
		
	if time == 0:
		finished.emit()
		return
	
	if time == LOW_TIME:
		low = true
		running_out.emit()
	
	if low:
		ticker.play()
	
	get_tree().create_timer(1).timeout.connect(func(): set_timer(time - 1))

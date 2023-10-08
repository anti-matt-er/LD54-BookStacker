extends Node3D


const LOW_TIME := 30

@onready var hand := $Hand
@onready var ticker := $Ticker
@onready var max_dimension: float = $Watch.get_aabb().get_longest_axis_size()
@onready var timer := Timer.new()

var remaining := 0
var total := 0
var low := false

signal finished
signal running_out


func _ready() -> void:
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(func(): set_timer(remaining - 1))


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
	
	timer.start(1)


func stop() -> void:
	timer.stop()
	ticker.stop()

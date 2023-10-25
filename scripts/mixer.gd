extends HSlider
class_name Mixer


@export var bus: String

@onready var bus_index := AudioServer.get_bus_index(bus)
@onready var bus_option := bus.to_lower() + "_volume"
@onready var ui_click := find_parent("Game").get_node("UIClickSFX")


func _ready() -> void:
	value = SaveManager.options[bus_option]
	set_volume(value)
	
	value_changed.connect(set_volume)
	mouse_entered.connect(ui_click.play)


func get_volume() -> float:
	return pow(10, AudioServer.get_bus_volume_db(bus_index) / 20.0) * 100


func set_volume(volume: float) -> void:
	SaveManager.options[bus_option] = volume
	AudioServer.set_bus_volume_db(bus_index, 20.0 * log(volume / 100) / log(10))
	AudioServer.set_bus_mute(bus_index, is_zero_approx(volume))
	
	ui_click.play()

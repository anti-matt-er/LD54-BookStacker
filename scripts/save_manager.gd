extends Node


var options := {
	"music_volume": 52.3299114681495,
	"sfx_volume": 100
}
var highscore := 0


func _ready() -> void:
	load_options()
	load_score()


func save_data(data: Dictionary, filename: String) -> void:
	var file = FileAccess.open("user://" + filename + ".save", FileAccess.WRITE)

	file.store_string(JSON.stringify(data))


func load_data(filename) -> Dictionary:
	if !FileAccess.file_exists("user://" + filename + ".save"):
		return {}
	
	var file = FileAccess.open("user://" + filename + ".save", FileAccess.READ)
	
	var data = JSON.parse_string(file.get_as_text())
	
	if data && data is Dictionary:
		return data
	
	else:
		return {}


func save_options() -> void:
	save_data(options, "options")


func load_options() -> void:
	var loaded_options = load_data("options")
	
	if !loaded_options.is_empty():
		options = loaded_options


func save_score() -> void:
	save_data({"highscore": highscore}, "highscore")


func load_score() -> void:
	var loaded_score = load_data("highscore")
	
	if !loaded_score.is_empty():
		highscore = loaded_score.highscore

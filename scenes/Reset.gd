extends TextButton


func action() -> void:
	for tutorial in SaveManager.tutorials.keys():
		SaveManager.tutorials[tutorial] = false
	
	SaveManager.save_tutorials()

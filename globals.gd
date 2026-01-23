extends Node

var config := ConfigFile.new()

func _ready() -> void:
	if not FileAccess.file_exists("user://save.ini"):
		config.save("user://save.ini")
	config.load("user://save.ini")

func cset(section, key, value):
	config.set_value(section, key, value)
	config.save("user://save.ini")

func cget(section, key, default = null):
	return config.get_value(section, key, default)

func cdel():
	config.clear()
	config.save("user://save.ini")

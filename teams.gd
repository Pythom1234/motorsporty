extends Node

const teams = {
	"c": [preload("res://assets/logos/mclaren.png"), "#FF7A00", "#1B1B1B", "#00C8FF"],
	"d": [preload("res://assets/logos/mercedes.png"), "#111111", "#00D2BE", "#FFFFFF"],
	"r": [preload("res://assets/logos/redbullracing.png"), "#1A2340", "#0A0A0A", "#E10600"],
	"f": [preload("res://assets/logos/ferrari.png"), "#B60000", "#D90000", "#FFD200"],
	"w": [preload("res://assets/logos/williams.png"), "#0033A0", "#001A4D", "#FFD200"],
	"i": [preload("res://assets/logos/racingbulls.png"), "#0090FF", "#000000", "#FFFFFF"],
	"m": [preload("res://assets/logos/astonmartin.png"), "#006F62", "#00332E", "#CEDC00"],
	"h": [preload("res://assets/logos/haasf1team.png"), "#2B2B2B", "#B6B6B6", "#E10600"],
	"u": [preload("res://assets/logos/kicksauber.png"), "#00E701", "#000000", "#FFFFFF"],
	"a": [preload("res://assets/logos/alpine.png"), "#005AFF", "#002766", "#FF4FD8"],
}

const codes = {
	"McLaren": "c",
	"Mercedes": "d",
	"Red Bull Racing": "r",
	"Ferrari": "f",
	"Williams": "w",
	"Racing Bulls": "i",
	"Aston Martin": "m",
	"Haas F1 Team": "h",
	"Kick Sauber": "u",
	"Alpine": "a",
}

const codes2 = {
	"c": "McLaren",
	"d": "Mercedes",
	"r": "Red Bull Racing",
	"f": "Ferrari",
	"w": "Williams",
	"i": "Racing Bulls",
	"m": "Aston Martin",
	"h": "Haas F1 Team",
	"u": "Kick Sauber",
	"a": "Alpine"
}

func get_material(code, id):
	var m = StandardMaterial3D.new()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(Teams.teams[code][id + 1])
	return m

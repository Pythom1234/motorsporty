extends Node3D

var target_position = Vector3()
var target_rotation = Vector3()
var label = "":
	set(x):
		if "[DEV]" in x:
			$Label/SubViewport/Control/Container/Name.label_settings.font_color = Color(0.0, 0.918, 1.0)
		else:
			$Label/SubViewport/Control/Container/Name.label_settings.font_color = Color(1.0, 1.0, 1.0)
		if x != null and x.length() > 0:
			$Label/SubViewport/Control/Container/Name.text = x.substr(0, x.length() - 1)
			if x[-1] in Teams.teams.keys():
				$Label/SubViewport/Control/Container/Team.texture = Teams.teams[x[-1]][0]
				$Base_textured.set_surface_override_material(0, Teams.get_material(x[-1]))
				if Teams.get_secondary_material(x[-1]):
					$Base_black.set_surface_override_material(0, Teams.get_secondary_material(x[-1]))

func _process(delta: float) -> void:
	quaternion = quaternion.slerp(Quaternion.from_euler(target_rotation), clamp(delta * 10, 0, 1))
	position = position.lerp(target_position, clamp(delta * 10, 0, 1))

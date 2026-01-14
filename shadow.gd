extends Node3D

var target_position = Vector3()
var target_rotation = Vector3()
var label = "":
	set(x):
		if x != null and x.length() > 0:
			$Label/SubViewport/Control/Container/Name.text = x.substr(0, x.length() - 1)
			if x[-1] in Teams.teams.keys():
				$Label/SubViewport/Control/Container/Team.texture = Teams.teams[x[-1]][0]
				$Base.set_surface_override_material(0, Teams.get_material(x[-1], 0))
				$Base.set_surface_override_material(2, Teams.get_material(x[-1], 1))
				$Base.set_surface_override_material(3, Teams.get_material(x[-1], 2))

func _process(delta: float) -> void:
	quaternion = quaternion.slerp(Quaternion.from_euler(target_rotation), clamp(delta * 10, 0, 1))
	position = position.lerp(target_position, clamp(delta * 10, 0, 1))

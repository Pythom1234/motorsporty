extends Area3D

func _ready() -> void:
	body_entered.connect(func(body: Node3D):
		if body.has_method("enter_area"):
			body.enter_area(self)
		)
	body_exited.connect(func(body: Node3D):
		if body.has_method("exit_area"):
			body.exit_area(self)
		)

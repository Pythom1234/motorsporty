extends Control

func _ready() -> void:
	$PanelContainer/GridContainer/Gravity.value = 2.0
	$PanelContainer/GridContainer/SteerMax.value = 12.0
	$PanelContainer/GridContainer/SteerMin.value = 2.2
	$PanelContainer/GridContainer/MaxSpeed.value = 250.0

func _on_gravity_value_changed(value: float) -> void:
	$PanelContainer/GridContainer/GravityLabel.text = "Gravity: %.1f" % value
	$"../../F1".gravity_scale = value

func _on_steer_max_value_changed(value: float) -> void:
	$PanelContainer/GridContainer/SteerMaxLabel.text = "Steer max: %.1f" % value
	$"../../F1"._dev_steer_max = value

func _on_steer_min_value_changed(value: float) -> void:
	$PanelContainer/GridContainer/SteerMinLabel.text = "Steer min: %.1f" % value
	$"../../F1"._dev_steer_min = value

func _on_max_speed_value_changed(value: float) -> void:
	$PanelContainer/GridContainer/MaxSpeedLabel.text = "Max speed: %d" % value
	$"../../F1"._dev_max_speed = value

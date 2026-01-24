extends Control

func _ready() -> void:
	$PanelContainer/GridContainer/Gravity.value = 2.0
	$PanelContainer/GridContainer/SteerMax.value = 13.5
	$PanelContainer/GridContainer/SteerMin.value = 2.9
	$PanelContainer/GridContainer/MaxSpeed.value = 250.0
	$PanelContainer/GridContainer/Acceleration.value = 6700.0
	$PanelContainer/GridContainer/Brake.value = 35.0
	if OS.get_name() == "Web":
		$PanelContainer/GridContainer/GravityLabel.pressed.connect(
			func():
				var val: String = JavaScriptBridge.eval("prompt('Value?')")
				if val.is_valid_float():
					$PanelContainer/GridContainer/Gravity.value = float(val)
		)
		$PanelContainer/GridContainer/SteerMaxLabel.pressed.connect(
			func():
				var val: String = JavaScriptBridge.eval("prompt('Value?')")
				if val.is_valid_float():
					$PanelContainer/GridContainer/SteerMax.value = float(val)
		)
		$PanelContainer/GridContainer/SteerMinLabel.pressed.connect(
			func():
				var val: String = JavaScriptBridge.eval("prompt('Value?')")
				if val.is_valid_float():
					$PanelContainer/GridContainer/SteerMin.value = float(val)
		)
		$PanelContainer/GridContainer/MaxSpeedLabel.pressed.connect(
			func():
				var val: String = JavaScriptBridge.eval("prompt('Value?')")
				if val.is_valid_float():
					$PanelContainer/GridContainer/MaxSpeed.value = float(val)
		)
		$PanelContainer/GridContainer/AccelerationLabel.pressed.connect(
			func():
				var val: String = JavaScriptBridge.eval("prompt('Value?')")
				if val.is_valid_float():
					$PanelContainer/GridContainer/Acceleration.value = float(val)
		)
		$PanelContainer/GridContainer/BrakeLabel.pressed.connect(
			func():
				var val: String = JavaScriptBridge.eval("prompt('Value?')")
				if val.is_valid_float():
					$PanelContainer/GridContainer/Brake.value = float(val)
		)

func _on_gravity_value_changed(value: float) -> void:
	$PanelContainer/GridContainer/GravityLabel.text = "Gravity: %.1f" % value
	$"../../Track/F1".gravity_scale = value

func _on_steer_max_value_changed(value: float) -> void:
	$PanelContainer/GridContainer/SteerMaxLabel.text = "Steer max: %.1f" % value
	$"../../Track/F1"._dev_steer_max = value

func _on_steer_min_value_changed(value: float) -> void:
	$PanelContainer/GridContainer/SteerMinLabel.text = "Steer min: %.1f" % value
	$"../../Track/F1"._dev_steer_min = value

func _on_max_speed_value_changed(value: float) -> void:
	$PanelContainer/GridContainer/MaxSpeedLabel.text = "Max speed: %d" % value
	$"../../Track/F1"._dev_max_speed = value

func _on_acceleration_value_changed(value: float) -> void:
	$PanelContainer/GridContainer/AccelerationLabel.text = "Acceleration: %d" % value
	$"../../Track/F1"._dev_acceleration = value

func _on_brake_value_changed(value: float) -> void:
	$PanelContainer/GridContainer/BrakeLabel.text = "Brake: %d" % value
	$"../../Track/F1"._dev_brake = value

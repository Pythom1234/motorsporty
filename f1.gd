extends VehicleBody3D

var lap = 0
var laps = 5
var checkpoints = []
var lap_start = 0
var race_start = 0
var best_time = 0
var keep_time = 0
var starting = -1
var penalty = 0
var checkpoint_times = [0, 0, 0]
var sector_start = 0

#TODO: remove
var _dev_steer_max = null
var _dev_steer_min = null
var _dev_max_speed = null
var _dev_acceleration = null
var _dev_brake = null

func format_time(time):
	return (
		"%d.%03d" % [int(time / 1000.0) % 60, time % 1000]
		if time < 60000 else
		"%d:%02d.%03d" % [int(time / 60000.0), int(time / 1000.0) % 60, time % 1000]
	)

func set_lights(num):
	for i in range($CanvasLayer/UI/Lights.get_child_count()):
		$CanvasLayer/UI/Lights.get_child(i).texture = (
			preload("res://assets/images/lights_off.png")
			if i >= num else
			preload("res://assets/images/lights_on.png")
		)

func set_team(code):
	$Base_textured.set_surface_override_material(0, Teams.get_material(code))
	if Teams.get_secondary_material(code):
		$Base_black.set_surface_override_material(0, Teams.get_secondary_material(code))

func _process(delta: float) -> void:
	get_node("Views/View_%s" % Globals.cget("settings", "camera", 0)).current = true
	var dir = global_transform.basis.z.dot(linear_velocity)
	var speed = linear_velocity.length()
	if starting != -1:
		%Time.text = format_time(0)
		$CanvasLayer/UI/Lights.visible = true
		set_lights(int(starting * 1.3))
		starting += delta
		if starting >= 5.5:
			set_lights(0)
			lap_start = Time.get_ticks_msec()
			race_start = Time.get_ticks_msec()
			sector_start = Time.get_ticks_msec()
			starting = -1
			await get_tree().create_timer(0.2).timeout
			$CanvasLayer/UI/Lights.visible = false
		if starting > 3 and (Input.is_action_pressed("forward") or Input.is_action_pressed("backward")):
			$"../..".alert("Jump start - 2s penalty", 5.5 - starting + 2)
			penalty = 2
	else:
		if keep_time <= 0:
			var time = Time.get_ticks_msec() - lap_start
			%Time.text = format_time(time)
		else:
			keep_time -= delta
	if starting != -1 or (not Input.is_action_pressed("forward") and not Input.is_action_pressed("backward")) or penalty > 0:
		brake = 17
	else:
		brake = 0
	if penalty <= 0:
		if starting == -1:
			engine_force = Input.get_axis("backward", "forward") * _dev_acceleration if _dev_acceleration else 6700.0
			if Input.get_axis("backward", "forward") < 0:
				engine_force *= 1.5
			if dir > 1:
				brake = Input.get_action_strength("backward") * _dev_brake if _dev_brake else 35.0
			elif dir < -1:
				brake = Input.get_action_strength("forward") * _dev_brake if _dev_brake else 35.0
	else:
		if starting == -1:
			penalty -= delta

	$CanvasLayer/UI/Speed.text = "%d km/h" % (speed * 3.6)
	%Lap.text = "Lap %d/%d" % [lap + 1, laps]

	var input_axis = Input.get_axis("right", "left")
	# NOTE: (speed * 3.6)
	#var max_steer = lerp(deg_to_rad(8.2), deg_to_rad(1.0), clamp(speed / 200.0, 0.0, 1.0))
	#var max_steer = lerp(
		#deg_to_rad(13.0),
		#deg_to_rad(2.2),
		#clamp((speed * 3.6) / (250.0), 0.0, 1.0)
	#)
	var max_steer = lerp(
		deg_to_rad(13.5 if _dev_steer_max == null else _dev_steer_max),
		deg_to_rad(2.9 if _dev_steer_min == null else _dev_steer_min),
		clamp((speed * 3.6) / (250.0 if _dev_max_speed == null else _dev_max_speed), 0.0, 1.0)
	)
	var target_steer = input_axis * max_steer
	steering = move_toward(steering, target_steer, delta * (0.5 + pow(target_steer - steering, 2)))

	var on_grass = false
	for wheel in get_children():
		if wheel is VehicleWheel3D and wheel.is_in_contact():
			var body = wheel.get_contact_body()
			if body.get_collision_layer_value(3):
				on_grass = true
				break
	if on_grass:
		brake = max(brake, lerp(20, 43, (speed * 3.6) / 250.0))

	#var downforce = speed * speed
	#apply_force(Vector3(0, -downforce, 0), Vector3(0, 0, 3))
	#apply_force(Vector3(0, -downforce, 0), Vector3(0, 0, -2))


func enter_area(area):
	const mapping = {
		"Start": 2,
		"Checkpoint1": 0,
		"Checkpoint2": 1
	}
	var time = Time.get_ticks_msec()
	if ((area.name == "Start" and len(checkpoints) == 2) or
		("Checkpoint" in area.name and not str(area.name)[-1] in checkpoints)):
			var n = time - sector_start
			sector_start = time
			var i = mapping[str(area.name)]
			var color
			if checkpoint_times[i] == 0:
				checkpoint_times[i] = n
				color = "#a72ebb"
			elif n < checkpoint_times[i]:
				checkpoint_times[i] = n
				color = "#a72ebb"
			elif n < checkpoint_times[i] + 1500:
				color = "#42dc40"
			else:
				color = "#cfb004"
			get_node("CanvasLayer/UI/Panel/MarginContainer/VBoxContainer/Sectors/S%d" % (i + 1)).color = Color(color)
	if area.name == "Start" and len(checkpoints) == 2:
		%Time.text = format_time(time - lap_start)
		keep_time = 2
		checkpoints = []
		lap += 1
		best_time = min(time - lap_start, best_time)
		if best_time == 0:
			best_time = time - lap_start
		lap_start = time
		%Best.text = "Best: " + format_time(best_time)
		if lap == laps:
			$"../..".finish(time - race_start)
		await get_tree().create_timer(2).timeout
		$CanvasLayer/UI/Panel/MarginContainer/VBoxContainer/Sectors/S1.color = Color(0.31, 0.31, 0.31, 1.0)
		$CanvasLayer/UI/Panel/MarginContainer/VBoxContainer/Sectors/S2.color = Color(0.31, 0.31, 0.31, 1.0)
		$CanvasLayer/UI/Panel/MarginContainer/VBoxContainer/Sectors/S3.color = Color(0.31, 0.31, 0.31, 1.0)
	if "Checkpoint" in area.name:
		if not str(area.name)[-1] in checkpoints:
			checkpoints.append(str(area.name)[-1])
	if "CC" in area.name:
		$"../..".alert("Warning: corner cutting", 3)

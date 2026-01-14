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

#TODO: remove
var _dev_steer_max = null
var _dev_steer_min = null
var _dev_max_speed = null

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
	$Base.set_surface_override_material(0, Teams.get_material(code, 0))
	$Base.set_surface_override_material(2, Teams.get_material(code, 1))
	$Base.set_surface_override_material(3, Teams.get_material(code, 2))

func _process(delta: float) -> void:
	var dir = -global_transform.basis.z.normalized().dot(linear_velocity.normalized())
	var speed = linear_velocity.length()
	if starting != -1:
		$CanvasLayer/UI/Lights.visible = true
		set_lights(int(starting * 1.3))
		starting += delta
		if starting >= 5.5:
			set_lights(0)
			lap_start = Time.get_ticks_msec()
			race_start = Time.get_ticks_msec()
			starting = -1
			await get_tree().create_timer(0.2).timeout
			$CanvasLayer/UI/Lights.visible = false
		if starting > 3 and (Input.is_action_pressed("forward") or Input.is_action_pressed("backward")):
			penalty = 2
	else:
		if keep_time <= 0:
			var time = Time.get_ticks_msec() - lap_start
			%Time.text = format_time(time)
		else:
			keep_time -= delta

	if penalty <= 0:
		$CanvasLayer/UI/Penalty.visible = false
		if starting == -1:
			if dir < -0.5:
				engine_force = Input.get_action_strength("forward") * 6700.0
				brake = Input.get_action_strength("backward") * 21.0
			elif dir > 0.5:
				engine_force = -Input.get_action_strength("backward") * 6700.0
				brake = Input.get_action_strength("forward") * 21.0
			else:
				engine_force = Input.get_axis("backward", "forward") * 6700.0
	else:
		$CanvasLayer/UI/Penalty.visible = true
		if starting == -1:
			penalty -= delta

	$CanvasLayer/UI/Speed.text = "%d km/h" % (speed * 3.6)
	%Lap.text = "Lap %d/%d" % [lap + 1, laps]

	if starting != -1 or (not Input.is_action_pressed("forward") and not Input.is_action_pressed("backward")):
		#engine_force = dir * 800
		brake = 20

	var input_axis = Input.get_axis("right", "left")
	# NOTE: (speed * 3.6)
	#var max_steer = lerp(deg_to_rad(8.2), deg_to_rad(1.0), clamp(speed / 200.0, 0.0, 1.0))
	var max_steer = lerp(
		deg_to_rad(20.0 if _dev_steer_max == null else _dev_steer_max),
		deg_to_rad(3.0 if _dev_steer_min == null else _dev_steer_min),
		clamp((speed * 3.6) / (300.0 if _dev_max_speed == null else _dev_max_speed), 0.0, 1.0)
	)
	var target_steer = input_axis * max_steer
	steering = move_toward(steering, target_steer, delta * (0.5 + pow(target_steer - steering, 2)))

	#var downforce = speed * speed
	#apply_force(Vector3(0, -downforce, 0), Vector3(0, 0, 3))
	#apply_force(Vector3(0, -downforce, 0), Vector3(0, 0, -2))

	if Input.is_action_just_pressed("camera"):
		const NUM_VIEWS = 6
		for i in range(NUM_VIEWS):
			if get_node("View_%s" % i).current:
				get_node("View_%s" % i).current = false
				get_node("View_%s" % ((i + 1) % NUM_VIEWS)).current = true
				break

func enter_area(area):
	if area.name == "Start" and len(checkpoints) == 4:
		var time = Time.get_ticks_msec()
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
			$"..".finish(time - race_start)
	if "Checkpoint" in area.name:
		if not str(area.name)[-1] in checkpoints:
			checkpoints.append(str(area.name)[-1])

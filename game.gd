extends Node3D

#const URL = "wss://motorsporty-pythom2org-4de6691e.koyeb.app/"
const URL = "ws://localhost:3000"
var socket = WebSocketPeer.new()
var connected = false
var shadows = {}
var race = false
var waiting_start = false
var sent_name = false
var names = {}
var my_name = ""

func _process(_delta: float):
	get_tree().paused = not race or waiting_start
	socket.poll()
	$Shadows.visible = not (waiting_start or $F1.starting != -1 or not connected)
	$F1/CanvasLayer/UI/Panel/MarginContainer/VBoxContainer/HBoxContainer/Place.visible = not (waiting_start or $F1.starting != -1 or not connected)
	$F1/CanvasLayer/UI/Laderboard.visible = not (waiting_start or $F1.starting != -1 or not connected)
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			recieve()
		send()
		if not sent_name:
			var data = my_name.to_utf8_buffer()
			var buffer = StreamPeerBuffer.new()
			buffer.big_endian = false
			buffer.resize(1 + data.size())
			buffer.put_8(1)
			buffer.put_data(data)
			socket.send(buffer.data_array)
			sent_name = true
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		if connected:
			socket.connect_to_url(URL)
			sent_name = false
			names = {}

func add_laderboard(n, rank, highlighted=false):
	if n == null or len(n) < 1:
		return
	var ls = LabelSettings.new()
	ls.font_size = 30
	var c = HBoxContainer.new()
	var v_place = Label.new()
	v_place.label_settings = ls
	v_place.text = "%d." % rank
	c.add_child(v_place)
	var v_team = TextureRect.new()
	v_team.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	if n[-1] in Teams.teams.keys():
		v_team.texture = Teams.teams[n[-1]][0]
	c.add_child(v_team)
	var v_name = Label.new()
	v_name.label_settings = ls
	v_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v_name.text = "%s" % n.substr(0, n.length() - 1)
	c.add_child(v_name)
	if highlighted:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.69, 0.69, 0.69, 0.557)
		s.corner_radius_bottom_left = 3
		s.corner_radius_bottom_right = 3
		s.corner_radius_top_left = 3
		s.corner_radius_top_right = 3
		var p = PanelContainer.new()
		p.add_child(c)
		p.add_theme_stylebox_override("panel", s)
		$F1/CanvasLayer/UI/Laderboard/MarginContainer/VBoxContainer.add_child(p)
	else:
		$F1/CanvasLayer/UI/Laderboard/MarginContainer/VBoxContainer.add_child(c)

func distance():
	var d = $Path.curve.get_closest_offset($F1.position)
	var ld = $Path.curve.get_baked_length() * $F1.lap
	if d > 1380 and len($F1.checkpoints) < 3:
		return ld
	return d + ld

func send():
	var buffer = StreamPeerBuffer.new()
	buffer.big_endian = false
	buffer.resize(29)
	buffer.put_u8(0)
	buffer.put_float(distance())
	buffer.put_float($F1.position.x)
	buffer.put_float($F1.position.y)
	buffer.put_float($F1.position.z)
	buffer.put_float($F1.rotation.x)
	buffer.put_float($F1.rotation.y)
	buffer.put_float($F1.rotation.z)
	socket.send(buffer.data_array)

func recieve():
	var array = socket.get_packet()
	if array.size() < 1:
		return
	var action = array.decode_u8(0)
	if action == 0:
		# sending near players
		if (array.size() - 5) % 26 != 0:
			return
		var place = array.decode_u16(1)
		var length = array.decode_u16(3)
		$F1/CanvasLayer/UI/Panel/MarginContainer/VBoxContainer/HBoxContainer/Place.text = "%d/%d" % [place, length]
		var seen = []
		var finished = []
		for i in range(5, array.size(), 26):
			var id = array.decode_u16(i)
			var pos =  Vector3(
				array.decode_float(i + 2),
				array.decode_float(i + 6),
				array.decode_float(i + 10)
			)
			var rot = Vector3(
				array.decode_float(i + 14),
				array.decode_float(i + 18),
				array.decode_float(i + 22)
			)
			seen.append(id)
			if not names.has(id):
				var buffer = StreamPeerBuffer.new()
				buffer.big_endian = false
				buffer.resize(3)
				buffer.put_8(2)
				buffer.put_u16(id)
				socket.send(buffer.data_array)
			if pos == Vector3(0, 0, 0):
				finished.append(id)
				continue
			var n
			if shadows.has(id):
				n = shadows[id]
			else:
				n = preload("res://shadow.tscn").instantiate()
				n.position = pos
				n.rotation = rot
				shadows[id] = n
				$Shadows.add_child(n)
			n.target_position = pos
			n.target_rotation = rot
			n.label = names.get(id)
		for id in shadows.keys():
			if not seen.has(id) or finished.has(id):
				shadows[id].queue_free()
				shadows.erase(id)
		for i in $F1/CanvasLayer/UI/Laderboard/MarginContainer/VBoxContainer.get_children():
			i.queue_free()
		var rank = max(1, place - 3)
		for i in seen:
			if rank == place:
				add_laderboard(my_name, rank, true)
				rank += 1
			add_laderboard(names.get(i), rank)
			rank += 1
		if rank == place:
			add_laderboard(my_name, rank, true)
			rank += 1
		if not seen:
			add_laderboard(my_name, rank, true)
	if action == 1:
		# sending name of ID
		if array.size() < 4:
			return
		var id = array.decode_u16(1)
		names[id] = array.slice(3, array.size()).get_string_from_utf8()
		if shadows.has(id):
			shadows[id].label = names[id]
	if action == 2:
		# start race
		if not waiting_start:
			return
		waiting_start = false
		$F1.starting = 0
		if array.size() < 2:
			return
		$F1.laps = array.decode_u8(1)
	if action == 3:
		# sending finish place
		if array.size() < 3:
			return
		$CanvasLayer/Finish/Panel/TabContainer/Finish/VBoxContainer/Place.visible = true
		$CanvasLayer/Finish/Panel/TabContainer/Finish/VBoxContainer/Place.text = "Place: " + str(array.decode_u16(1))
	if action == 4:
		# kick
		connected = false
		socket.close()
		get_tree().reload_current_scene()

func start_local() -> void:
	$F1.starting = 0
	race = true
	$CanvasLayer/Prepare.visible = false
	$F1.set_team(Teams.codes[$CanvasLayer/Prepare/Panel/TabContainer/Online/VBoxContainer/Team/Team.get_item_text($CanvasLayer/Prepare/Panel/TabContainer/Local/VBoxContainer/Team/Team.selected)])
	$F1.laps = int($CanvasLayer/Prepare/Panel/TabContainer/Local/VBoxContainer/Laps/Laps.text)
	get_tree().paused = not race

func start_online() -> void:
	var nam = $CanvasLayer/Prepare/Panel/TabContainer/Online/VBoxContainer/Name/Name.text
	var team = $CanvasLayer/Prepare/Panel/TabContainer/Online/VBoxContainer/Team/Team.get_item_text($CanvasLayer/Prepare/Panel/TabContainer/Online/VBoxContainer/Team/Team.selected)
	my_name = nam + Teams.codes[team][0]
	connected = true
	race = true
	$CanvasLayer/Prepare.visible = false
	$F1.set_team(Teams.codes[$CanvasLayer/Prepare/Panel/TabContainer/Online/VBoxContainer/Team/Team.get_item_text($CanvasLayer/Prepare/Panel/TabContainer/Online/VBoxContainer/Team/Team.selected)])
	get_tree().paused = false
	waiting_start = true
	$F1/CanvasLayer/UI/Lights.visible = true
	socket.connect_to_url(URL)
	sent_name = false

func start_devmode() -> void:
	$CanvasLayer/DevMode.visible = true
	race = true
	$CanvasLayer/Prepare.visible = false
	$F1.laps = 5
	$F1.lap_start = Time.get_ticks_msec()
	$F1.race_start = Time.get_ticks_msec()
	get_tree().paused = not race

func finish(time):
	get_tree().paused = true
	$CanvasLayer/Finish.visible = true
	$CanvasLayer/Finish/Panel/TabContainer/Finish/VBoxContainer/Place.visible = false
	$CanvasLayer/Finish/Panel/TabContainer/Finish/VBoxContainer/Time.text = "Time: " + $F1.format_time(time)
	$CanvasLayer/Finish/Panel/TabContainer/Finish/VBoxContainer/BestTime.text = "Best lap time: " + $F1.format_time($F1.best_time)
	if connected:
		$CanvasLayer/Finish/Panel/TabContainer/Finish/VBoxContainer/Name.visible = true
		$CanvasLayer/Finish/Panel/TabContainer/Finish/VBoxContainer/Name.text = "Name: " + my_name.substr(0, my_name.length() - 1)
		var state = socket.get_ready_state()
		while state != WebSocketPeer.STATE_OPEN:
			pass
		var buffer = StreamPeerBuffer.new()
		buffer.big_endian = false
		buffer.resize(1)
		buffer.put_u8(3)
		socket.send(buffer.data_array)

func retry() -> void:
	get_tree().reload_current_scene()

func _minus_pressed() -> void:
	$CanvasLayer/Prepare/Panel/TabContainer/Local/VBoxContainer/Laps/Laps.text = str(clamp(int($CanvasLayer/Prepare/Panel/TabContainer/Local/VBoxContainer/Laps/Laps.text) - 1, 1, 100))

func _plus_pressed() -> void:
	$CanvasLayer/Prepare/Panel/TabContainer/Local/VBoxContainer/Laps/Laps.text = str(clamp(int($CanvasLayer/Prepare/Panel/TabContainer/Local/VBoxContainer/Laps/Laps.text) + 1, 1, 100))

func _minus_2_pressed() -> void:
	$CanvasLayer/Prepare/Panel/TabContainer/Local/VBoxContainer/Laps/Laps.text = str(clamp(int($CanvasLayer/Prepare/Panel/TabContainer/Local/VBoxContainer/Laps/Laps.text) - 5, 1, 100))

func _plus_2_pressed() -> void:
	$CanvasLayer/Prepare/Panel/TabContainer/Local/VBoxContainer/Laps/Laps.text = str(clamp(int($CanvasLayer/Prepare/Panel/TabContainer/Local/VBoxContainer/Laps/Laps.text) + 5, 1, 100))

func _name_focus_entered() -> void:
	var edit = $CanvasLayer/Prepare/Panel/TabContainer/Online/VBoxContainer/Name/Name
	if OS.get_name() == "Web":
		var text = JavaScriptBridge.eval("prompt('Your name?', '%s')" % edit.text.replace("'", "\\'"))
		edit.text = text if text != null else edit.text
		edit.release_focus.call_deferred()
	check_connect(edit.text, null)

func _name_text_changed(new_text: String) -> void:
	check_connect(new_text, null)

func _team_item_selected(index: int) -> void:
	check_connect(null, index)

func check_connect(n, t):
	if n == null:
		n = $CanvasLayer/Prepare/Panel/TabContainer/Online/VBoxContainer/Name/Name.text
	if t == null:
		t = $CanvasLayer/Prepare/Panel/TabContainer/Online/VBoxContainer/Team/Team.selected
	$CanvasLayer/Prepare/Panel/TabContainer/Online/VBoxContainer/Connect.disabled = n == "" or t == -1

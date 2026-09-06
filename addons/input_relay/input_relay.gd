## Global InputRelay manager
extends Node

## Emitted when device is connected
signal device_connected(id: int)
## Emitted when device is disconnected, may contain owner's number, or 0 for no owner
signal device_disconnected(id: int, owner: int)

const KEYBOARD_INDEX := InputEvent.DEVICE_ID_KEYBOARD

# Default values for helper vibrations (weak_motor, strong_motor, duration)
const _HAPTIC_TAP = 	Vector3(0.15, 0.08, 0.05)
const _HAPTIC_WEAK = 	Vector3(0.25, 0.15, 0.10)
const _HAPTIC_MEDIUM = 	Vector3(0.45, 0.30, 0.15)
const _HAPTIC_STRONG = 	Vector3(0.75, 0.55, 0.25)

# Default setting for remap helper
const _DEFAULT_REMAP_ESCAPE_KEYBOARD := [
	InputActionDef.MouseKeyButton.ESCAPE,
]
const _DEFAULT_REMAP_ESCAPE_JOY := [
	InputActionDef.JoypadButton.START,
	InputActionDef.JoypadButton.GUIDE,
]

## Max number of players, loaded from ProjectSetting("InputRelay/max_players").
var MAX_PLAYERS: int

## All connected [InputRelayDevice]s
var devices: Array[InputRelayDevice]
## All [InputRelayPlayer]s
var players: Array[InputRelayPlayer]
## Relay settings
var settings: InputRelaySettings
## Handle remapping of input
var remapper: InputRelayMapper
## Last player to receive input from, or 0 if received from unassigned device
var last_player_input: int

func _ready() -> void:
	# Get settings
	settings = ProjectSettings.get_setting("InputRelay/settings_resource", InputRelaySettings.new())
	if settings == null:
		settings = InputRelaySettings.new()
		push_error("No InputRelaySettings provided!")
	# Setup players
	MAX_PLAYERS = ProjectSettings.get_setting("InputRelay/max_players", 4)
	players.resize(MAX_PLAYERS)
	for n in players.size():
		# Assign number starting at 1
		players[n] = InputRelayPlayer.new(n + 1)
	# Setup remapper
	remapper = InputRelayMapper.new()
	# Setup device connections
	Input.joy_connection_changed.connect(_joy_connection_changed)
	for id in Input.get_connected_joypads():
		_register_device(id)
	match OS.get_name(): # If on PC we should register Keyboard & Mouse
		"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD", "Web":
			_register_device(KEYBOARD_INDEX, "Keyboard & Mouse")
		_:
			pass
	# Set player action sets to defaults
	for n in players.size():
		set_player_action_set(n + 1, settings.default_action_set)
	# Load initial mappings
	remapper.refresh_mappings()

func _input(event: InputEvent) -> void:
	# Udpdate information on last player and device input has been received from
	# This information is important for knowing what glyphs to use for players
	last_player_input = get_device_owner(event.device)
	if last_player_input != 0:
		if event.device == InputEvent.DEVICE_ID_MOUSE || event.device == InputEvent.DEVICE_ID_KEYBOARD:
			get_player(last_player_input).last_device = KEYBOARD_INDEX
		else:
			get_player(last_player_input).last_device = event.device

func _joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		_register_device(device_id)
	else:
		_unregister_device(device_id)

func _register_device(device_id: int, device_name: String = "") -> void:
	if device_name.is_empty():
		if Input.get_connected_joypads().has(device_id):
			device_name = Input.get_joy_name(device_id)
		else:
			device_name = "???"
	var device := InputRelayDevice.new(device_id, device_name, settings)
	devices.append(device)
	device_connected.emit(device_id)
	# Check if device should be auto-assigned based on project settings
	# By default used to assign keyboard and first connected device to player 1
	if device_id == KEYBOARD_INDEX\
	and ProjectSettings.get_setting("InputRelay/player_1_auto_assign_keyboard", true):
		assign_device(device_id, 1)
	elif !player_has_non_keyboard_devices(1)\
	and ProjectSettings.get_setting("InputRelay/player_1_auto_assign_first_device", true):
		assign_device(device_id, 1)

func _unregister_device(device_id: int) -> void:
	var device := get_device(device_id)
	var player := device.player
	if player != null:
		unassign_device(device_id, device.player.number)
	devices.erase(device)
	if player:
		device_disconnected.emit(device_id, player.number)
	else:
		device_disconnected.emit(device_id, 0)
	# Stop any vibration just to be safe
	if Input.get_connected_joypads().has(device_id):
		Input.stop_joy_vibration(device_id)

func assign_device(device_id: int, player_number: int) -> void:
	var device := get_device(device_id)
	var player := get_player(player_number)
	if device == null || player == null:
		push_error("Passed invalid player or device number for device assignment")
	if device.player != null:
		unassign_device(device_id, device.player.number)
	player.devices.append(device)
	device.player = player
	if device.supports_lights():
		Input.set_joy_light(device.index, player.color)
	remapper.refresh_mappings()

func unassign_device(device_id: int, player_number: int) -> void:
	var device := get_device(device_id)
	var player := get_player(player_number)
	if device == null || player == null:
		push_error("Passed invalid player or device number for device unassignment")
	if device.player == player:
		device.player == null
	if player.devices.has(device):
		player.devices.erase(device)
	# Stop any vibration
	if Input.get_connected_joypads().has(device_id):
		Input.stop_joy_vibration(device_id)
	if device.supports_lights():
		Input.set_joy_light(device.index, Color.WHITE)
	remapper.refresh_mappings()

func clear_devices(player_number: int) -> void:
	var player := get_player(player_number)
	if player == null:
		push_error("Passed invalid player number for device unassignment")
	for device in player.devices.duplicate():
		unassign_device(device.index, player_number)

func get_player(player_number: int) -> InputRelayPlayer:
	if player_number < 0 || player_number > players.size():
		push_error("Trying to get player number that doesn't exist")
		return null
	return players[player_number - 1]

func get_device(index: int) -> InputRelayDevice:
	for device in devices:
		if device.index == index:
			return device
	return null

func player_has_devices(player_number: int) -> bool:
	return not get_player(player_number).devices.is_empty()

func player_has_non_keyboard_devices(player_number: int) -> bool:
	for device in get_player(player_number).devices:
		if device.index != KEYBOARD_INDEX:
			return true
	return false

func device_is_assigned(device_id: int) -> bool:
	var device := get_device(device_id)
	return device != null && device.player != null

## Vibrates all player devices using [param weak_motor] and [param strong_motor]
## to determine magnitude, and [param duration] to determine how long.
## [param duration] of 0.0 will play for as long as possible. Use 0 for all players.
func vibrate_player(player: int, weak_motor: float, strong_motor: float, duration: float) -> void:
	if player < 0 || player > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range for vibration: %d" % player)
		return
	if player == 0:
		for n in range(1, MAX_PLAYERS + 1):
			for device in get_player(n).devices:
				if not device.supports_haptic(): continue
				Input.start_joy_vibration(device.index, weak_motor, strong_motor, duration)
		return
	for device in get_player(player).devices:
		if not device.supports_haptic(): continue
		Input.start_joy_vibration(device.index, weak_motor, strong_motor, duration)

## Returns true if any of player devices are currently vibrating. Use 0 for all players.
func player_is_vibrating(player: int) -> bool:
	if player < 0 || player > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range for vibration: %d" % player)
		return false
	if player == 0:
		for n in range(1, MAX_PLAYERS + 1):
			for device in get_player(n).devices:
				if not device.supports_haptic(): continue
				if Input.is_joy_vibrating(device.index): return true
		return false
	for device in get_player(player).devices:
		if not device.supports_haptic(): continue
		if Input.is_joy_vibrating(device.index): return true
	return false

## Stop all player devices from vibrating. Use 0 for all players.
func stop_vibrating_player(player: int) -> void:
	if player < 0 || player > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range for vibration: %d" % player)
		return
	if player == 0:
		for n in range(1, MAX_PLAYERS + 1):
			for device in get_player(player).devices:
				if not device.supports_haptic(): continue
				Input.stop_joy_vibration(device.index)
		return
	for device in players[player].devices:
		if not device.supports_haptic(): continue
		Input.stop_joy_vibration(device.index)

## Helper function for very small 'tap' haptics (e.g. UI selection, item pickups)
func vibrate_player_tap(player: int) -> void:
	vibrate_player(player, _HAPTIC_TAP.x, _HAPTIC_TAP.y, _HAPTIC_TAP.z)

## Helper function for weak vibrations (e.g. footsteps, minor interactions)
func vibrate_player_weak(player: int) -> void:
	vibrate_player(player, _HAPTIC_WEAK.x, _HAPTIC_WEAK.y, _HAPTIC_WEAK.z)

## Helper function for medium strength vibrations (e.g. collisions)
func vibrate_player_medium(player: int) -> void:
	vibrate_player(player, _HAPTIC_MEDIUM.x, _HAPTIC_MEDIUM.y, _HAPTIC_MEDIUM.z)

## Helper function for very strong vibrations (e.g. heavy impacts)
func vibrate_player_strong(player: int) -> void:
	vibrate_player(player, _HAPTIC_STRONG.x, _HAPTIC_STRONG.y, _HAPTIC_STRONG.z)

## Returns list of devices currently not assigned to a player
func unassigned_devices() -> Array[InputRelayDevice]:
	return devices.filter(func(device: InputRelayDevice): device.player == null)

## Returns player number that device is assigned to, or 0 if is unassigned.
## [member InputEvent.DEVICE_ID_MOUSE] and [member InputEvent.DEVICE_ID_KEYBOARD]
## get changed to [member KEYBOARD_INDEX].
func get_device_owner(device_id: int) -> int:
	if device_id == InputEvent.DEVICE_ID_MOUSE || device_id == InputEvent.DEVICE_ID_KEYBOARD:
		device_id = KEYBOARD_INDEX
	for device in devices:
		if device.index == device_id:
			if device.player == null:
				return 0
			return device.player.number
	return 0

## Changes player's active action set. Clears active layers since they belong to the old set.
func set_player_action_set(player_number: int, set_key: StringName) -> void:
	if player_number <= 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range for set change: %d" % player_number)
		return
	if not settings.action_sets.has(set_key):
		push_error("No InputActionSet found for key %s" % set_key)
		return
	var player := get_player(player_number)
	player.current_action_set = set_key
	player.current_action_layers.clear()
	if has_mouse_and_keyboard_assigned(player_number): # Update mouse mode if keyboard player
		var using_joy := player.last_device != KEYBOARD_INDEX
		get_player_action_set_and_layers(player_number).pop_back().apply_mouse_mode(using_joy)
	remapper.refresh_mappings()

## Changes player's active layers. Must be part of player's current set.
## Pass empty array to clear layers. First layers in array have lowest priority.
func set_player_action_layers(player_number: int, layer_keys: Array[StringName]) -> void:
	if player_number <= 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range for set change: %d" % player_number)
		return
	var player := get_player(player_number)
	var action_set: InputActionSet = settings.action_sets.get(player.current_action_set)
	if action_set == null:
		push_error("Player has no valid action set assigned")
		return
	for layer_key in layer_keys:
		if not action_set.layers.has(layer_key):
			push_error("No layer found for key %s in set %s" % [layer_key, player.current_action_set])
			return
	player.current_action_layers = layer_keys
	if has_mouse_and_keyboard_assigned(player_number): # Update mouse mode if keyboard player
		var using_joy := player.last_device != KEYBOARD_INDEX
		get_player_action_set_and_layers(player_number).pop_back().apply_mouse_mode(using_joy)
	remapper.refresh_mappings()

## Returns true if player has Mouse and Keyboard assigned to them.
func has_mouse_and_keyboard_assigned(player_number: int) -> bool:
	if player_number <= 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range to check device assignments: %d" % player_number)
		return false
	var player := get_player(player_number)
	for device in player.devices:
		if device.index == KEYBOARD_INDEX:
			return true
	return false

## Returns player's action set and layers. Action set will be in index 0 of array.
func get_player_action_set_and_layers(player_number: int) -> Array[InputActionSet]:
	var output: Array[InputActionSet] = []
	if player_number <= 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range to get action set: %d" % player_number)
		return []
	var player := get_player(player_number)
	var action_set: InputActionSet = settings.action_sets.get(player.current_action_set)
	if action_set == null:
		push_error("Player has no valid action set assigned")
		return []
	for layer_key in player.current_action_layers:
		if action_set.layers.has(layer_key):
			output.append(action_set.layers[layer_key])
	return output

## Waits for next input, remaps dpad's up direction. Player 0 accepts any device and overwrites
## for all players. Returns true if applied. Call with await.
func remap_dpad_up_await(set_key: StringName, layer_key: StringName, action_name: StringName,
						player_number: int, timeout_seconds: float = 5.0,
						escape_key_mouse_buttons: Array[InputActionDef.MouseKeyButton] = _DEFAULT_REMAP_ESCAPE_KEYBOARD,
						escape_joy_buttons: Array[InputActionDef.JoypadButton] = _DEFAULT_REMAP_ESCAPE_JOY
						) -> bool:
	return await _await_next_button_directional(
		set_key,
		layer_key,
		action_name,
		player_number,
		0,
		timeout_seconds,
		escape_key_mouse_buttons,
		escape_joy_buttons
		)

## Waits for next input, remaps dpad's down direction. Player 0 accepts any device and overwrites
## for all players. Returns true if applied. Call with await.
func remap_dpad_down_await(set_key: StringName, layer_key: StringName, action_name: StringName,
							player_number: int, timeout_seconds: float = 5.0,
							escape_key_mouse_buttons: Array[InputActionDef.MouseKeyButton] = _DEFAULT_REMAP_ESCAPE_KEYBOARD,
							escape_joy_buttons: Array[InputActionDef.JoypadButton] = _DEFAULT_REMAP_ESCAPE_JOY
							) -> bool:
	return await _await_next_button_directional(
		set_key,
		layer_key,
		action_name,
		player_number,
		1,
		timeout_seconds,
		escape_key_mouse_buttons,
		escape_joy_buttons
		)

## Waits for next input, remaps dpad's left direction. Player 0 accepts any device and overwrites
## for all players. Returns true if applied. Call with await.
func remap_dpad_left_await(set_key: StringName, layer_key: StringName, action_name: StringName,
							player_number: int, timeout_seconds: float = 5.0,
							escape_key_mouse_buttons: Array[InputActionDef.MouseKeyButton] = _DEFAULT_REMAP_ESCAPE_KEYBOARD,
							escape_joy_buttons: Array[InputActionDef.JoypadButton] = _DEFAULT_REMAP_ESCAPE_JOY
							) -> bool:
	return await _await_next_button_directional(
		set_key,
		layer_key,
		action_name,
		player_number,
		2,
		timeout_seconds,
		escape_key_mouse_buttons,
		escape_joy_buttons
		)

## Waits for next input, remaps dpad's right direction. Player 0 accepts any device and overwrites
## for all players. Returns true if applied. Call with await.
func remap_dpad_right_await(set_key: StringName, layer_key: StringName, action_name: StringName,
							player_number: int, timeout_seconds: float = 5.0,
							escape_key_mouse_buttons: Array[InputActionDef.MouseKeyButton] = _DEFAULT_REMAP_ESCAPE_KEYBOARD,
							escape_joy_buttons: Array[InputActionDef.JoypadButton] = _DEFAULT_REMAP_ESCAPE_JOY
							) -> bool:
	return await _await_next_button_directional(
		set_key,
		layer_key,
		action_name,
		player_number,
		3,
		timeout_seconds,
		escape_key_mouse_buttons,
		escape_joy_buttons
		)

## Shared logic for the four dpad direction helpers above. direction_index: 0=up,1=down,2=left,3=right
func _await_next_button_directional(set_key: StringName, layer_key: StringName, action_name: StringName,
									player_number: int,
									direction_index: int,
									timeout_seconds: float,
									escape_key_mouse_buttons: Array[InputActionDef.MouseKeyButton],
									escape_joy_buttons: Array[InputActionDef.JoypadButton]
									) -> bool:
	if player_number < 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range for set change: %d" % player_number)
		return false
	var devices := _remap_devices_for_player(player_number)
	var result := await _await_next_button(devices, timeout_seconds, escape_key_mouse_buttons, escape_joy_buttons)
	if not result.accepted:
		return false
	var up := -1
	var down := -1
	var left := -1
	var right := -1
	if result.is_key_mouse:
		match direction_index:
			0: up = result.key_mouse_button
			1: down = result.key_mouse_button
			2: left = result.key_mouse_button
			3: right = result.key_mouse_button
		for target_player in _remap_target_players(player_number):
			remapper.remap_directional_key_mouse(set_key, layer_key, action_name, target_player, up, down, left, right)
	else:
		match direction_index:
			0: up = result.joy_button
			1: down = result.joy_button
			2: left = result.joy_button
			3: right = result.joy_button
		for target_player in _remap_target_players(player_number):
			remapper.remap_directional_joy_button(set_key, layer_key, action_name, target_player, up, down, left, right)
	return true

## Devices to listen on for a remap: player's own devices, or every connected device for player 0
func _remap_devices_for_player(player_number: int) -> Array[InputRelayDevice]:
	if player_number == 0:
		return devices.duplicate()
	return get_player(player_number).devices

## Players whose remap should be written: just player_number, or every player for 0
func _remap_target_players(player_number: int) -> Array[int]:
	if player_number == 0:
		var all_players: Array[int] = []
		for n in range(1, InputRelay.MAX_PLAYERS + 1):
			all_players.append(n)
		return all_players
	return [player_number]

## Polls devices each frame for a newly pressed button. Ignores anything already
## held when listening starts. Returns {accepted, is_key_mouse, key_mouse_button/joy_button}
func _await_next_button(listen_devices: Array[InputRelayDevice], timeout_seconds: float,
						escape_key_mouse_buttons: Array[InputActionDef.MouseKeyButton],
						escape_joy_buttons: Array[InputActionDef.JoypadButton]
						) -> Dictionary:
	var deadline_msec := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	var has_keyboard := listen_devices.any(func(device): return device.index == KEYBOARD_INDEX)
	var joy_device_ids: Array[int] = []
	for device in listen_devices:
		if device.index != KEYBOARD_INDEX:
			joy_device_ids.append(device.index)
	
	var previous_key_mouse := _poll_pressed_mouse_key_button() if has_keyboard else InputActionDef.MouseKeyButton.NONE
	var previous_joy: Dictionary = {}
	for device_id in joy_device_ids:
		previous_joy[device_id] = _poll_pressed_joy_button(device_id)
	
	while Time.get_ticks_msec() < deadline_msec:
		await get_tree().process_frame
		if has_keyboard:
			var button := _poll_pressed_mouse_key_button()
			if button != InputActionDef.MouseKeyButton.NONE and button != previous_key_mouse:
				if escape_key_mouse_buttons.has(button):
					return {"accepted": false}
				return {"accepted": true, "is_key_mouse": true, "key_mouse_button": button}
			previous_key_mouse = button
		for device_id in joy_device_ids:
			var button := _poll_pressed_joy_button(device_id)
			if button != InputActionDef.JoypadButton.NONE and button != previous_joy[device_id]:
				if escape_joy_buttons.has(button):
					return {"accepted": false}
				return {"accepted": true, "is_key_mouse": false, "joy_button": button}
			previous_joy[device_id] = button
	return {"accepted": false}

## Returns first currently pressed MouseKeyButton, or NONE
func _poll_pressed_mouse_key_button() -> InputActionDef.MouseKeyButton:
	for button in InputActionDef.MouseKeyButton.values():
		if button == InputActionDef.MouseKeyButton.NONE:
			continue
		if InputActionDef.is_mouse_button(button):
			if Input.is_mouse_button_pressed(InputActionDef.mouse_key_button_to_mouse_button(button)):
				return button
		elif Input.is_physical_key_pressed(InputActionDef.mouse_key_button_to_key(button)):
			return button
	return InputActionDef.MouseKeyButton.NONE

## Returns first currently pressed JoypadButton on [param device_id], or NONE
func _poll_pressed_joy_button(device_id: int) -> InputActionDef.JoypadButton:
	for button in InputActionDef.JoypadButton.values():
		if button == InputActionDef.JoypadButton.NONE:
			continue
		if InputActionDef.is_axis_button(button):
			if Input.get_joy_axis(device_id, InputActionDef.joypad_button_to_joy_axis(button)) > 0.5:
				return button
		elif Input.is_joy_button_pressed(device_id, InputActionDef.joypad_button_to_joy_button(button)):
			return button
	return InputActionDef.JoypadButton.NONE

## Returns the display glyph for an action, based on player's last used device.
## Will use [member DeviceGlyphMap.fallback_glyph] if input is null.
func get_player_action_glyph(player_number: int, action_name: StringName) -> Texture2D:
	if player_number <= 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range to grab action glyph: %d" % player_number)
		return null
	var device := get_device(get_player(player_number).last_device)
	if device == null || device.glyph_map == null:
		return null
	var button_name := _get_player_action_button_name(player_number, action_name, device.index == KEYBOARD_INDEX)
	var glyph: Texture2D = device.glyph_map.get("%s_glyph"%button_name)
	if glyph == null:
		return device.glyph_map.fallback_glyph
	return glyph

## Returns the display string for an action, based on player's last used device.
func get_player_action_string(player_number: int, action_name: StringName) -> StringName:
	if player_number <= 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range to grab action glyph string: %d" % player_number)
		return &""
	var device := get_device(get_player(player_number).last_device)
	if device == null || device.glyph_map == null:
		return &""
	var button_name := _get_player_action_button_name(player_number, action_name, device.index == KEYBOARD_INDEX)
	if button_name.is_empty():
		return &""
	return device.glyph_map.get("%s_string"%button_name)

## Resolves an action's currently bound button, respecting remaps, as a [DeviceGlyphMap] property prefix.
func _get_player_action_button_name(player_number: int, action_name: StringName, is_keyboard: bool) -> String:
	# Find InputActionDef...
	var player := get_player(player_number)
	if player == null: return ""
	var action_set: InputActionSet = settings.action_sets.get(player.current_action_set)
	if action_set == null: return ""
	var action_def: InputActionDef = action_set.actions.get(action_name)
	var layer_key: StringName = &""
	for active_layer in player.current_action_layers:
		var layer: InputActionSet = action_set.layers.get(active_layer)
		if layer != null && layer.actions.has(action_name):
			action_def = layer.actions[action_name]
			layer_key = active_layer
	if action_def == null: return ""
	# ....We can now resolve the name
	if action_def is InputActionDefStickPad || action_def is InputActionDefDpad:
		# _get_player_directional_action_button_name should be used to fetch directionals, just grab up
		if is_keyboard:
			var button := remapper.get_remap_directional_key_mouse(player.current_action_set,layer_key, action_name, player_number)[0]
			if button == InputActionDef.MouseKeyButton.NONE:
				return ""
			return InputActionDef.mouse_key_button_to_string(button).to_lower()
		else: # Is joy
			var button := remapper.get_remap_directional_joy_button(player.current_action_set, layer_key, action_name, player_number)[0]
			if button == InputActionDef.JoypadButton.NONE:
				return ""
			return InputActionDef.joypad_button_to_string(button).to_lower()
	if is_keyboard:
		var button := remapper.get_remap_key_mouse(player.current_action_set, layer_key, action_name, player_number)
		if button == InputActionDef.MouseKeyButton.NONE:
			return ""
		return InputActionDef.mouse_key_button_to_string(button).to_lower()
	else:
		var button := remapper.get_remap_joy_button(player.current_action_set, layer_key, action_name, player_number)
		if button == InputActionDef.JoypadButton.NONE:
			return ""
		return InputActionDef.joypad_button_to_string(button).to_lower()

## Returns the display glyph for an action, based on player's last used device, for directional actions.
## [param direction] can specify "up", "down", "left", "right", or be left blank for unspecified direction.
## Will fallback to unspecified direction, or use [member DeviceGlyphMap.fallback_glyph] if input is null.
func get_player_directional_action_glyph(player_number: int, action_name: StringName, direction: String = "") -> Texture2D:
	direction = direction.to_lower()
	match direction:
		"up", "down", "left", "right":
			pass # No change needed
		_:
			direction = "" # Unknown direction, treat as blank
	if player_number <= 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range to grab action glyph: %d" % player_number)
		return null
	var device := get_device(get_player(player_number).last_device)
	if device == null || device.glyph_map == null:
		return null
	var button_name := _get_player_directional_action_button_name(player_number, action_name,
		device.index == KEYBOARD_INDEX, direction)
	var glyph: Texture2D = device.glyph_map.get("%s_glyph"%button_name)
	if glyph == null:
		if !direction.is_empty(): # Try fallback to unspecified direction
			glyph = device.glyph_map.get("%s_glyph"%button_name.trim_suffix("_%s"%direction))
			if glyph == null: # Still null?
				return device.glyph_map.fallback_glyph
	return glyph

## Returns the display string for an action, based on player's last used device, for directional actions.
## [param direction] can specify "up", "down", "left", "right", or be left blank for unspecified direction.
func get_player_directional_action_string(player_number: int, action_name: StringName, direction: String = "") -> StringName:
	direction = direction.to_lower()
	match direction:
		"up", "down", "left", "right":
			pass # No change needed
		_:
			direction = "" # Unknown direction, treat as blank
	if player_number <= 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range to grab action glyph string: %d" % player_number)
		return &""
	var device := get_device(get_player(player_number).last_device)
	if device == null || device.glyph_map == null:
		return &""
	var button_name := _get_player_directional_action_button_name(player_number, action_name,
		device.index == KEYBOARD_INDEX, direction)
	if button_name.is_empty():
		return &""
	return device.glyph_map.get("%s_string"%button_name)

## Resolves a directional action's currently bound button, respecting remaps, as a [DeviceGlyphMap] property prefix.
## [param direction] can specify "up", "down", "left", "right", or be left blank for unspecified direction.
func _get_player_directional_action_button_name(player_number: int, action_name: StringName, is_keyboard: bool, direction: String = "") -> String:
	direction = direction.to_lower()
	match direction:
		"up", "down", "left", "right":
			pass # No change needed
		_:
			direction = "" # Unknown direction, treat as blank
	# Find InputActionDef...
	var player := get_player(player_number)
	if player == null: return ""
	var action_set: InputActionSet = settings.action_sets.get(player.current_action_set)
	if action_set == null: return ""
	var action_def: InputActionDef = action_set.actions.get(action_name)
	var layer_key: StringName = &""
	for active_layer in player.current_action_layers:
		var layer: InputActionSet = action_set.layers.get(active_layer)
		if layer != null && layer.actions.has(action_name):
			action_def = layer.actions[action_name]
			layer_key = active_layer
	if action_def == null: return ""
	# ....We can now resolve the name
	if action_def is InputActionDefStickPad || action_def is InputActionDefDpad:
		if is_keyboard: # Prefer mouse if available
			if action_def is InputActionDefStickPad && action_def.mouse_motion:
				if direction.is_empty():
					return &"mouse_motion"
				else:
					return &"mouse_%s"%direction
			else: # Fallback to digital input
				var index: int
				match direction:
					"up": index = 0
					"down": index = 1
					"left": index = 2
					"right": index = 3
					_: index = 0 # Up is default for unspecified
				var button := remapper.get_remap_directional_key_mouse(player.current_action_set,layer_key, action_name, player_number)[index]
				if button == InputActionDef.MouseKeyButton.NONE:
					return ""
				return InputActionDef.mouse_key_button_to_string(button).to_lower()
		else: # Is joy
			if action_def is InputActionDefStickPad:
				var motion := remapper.get_remap_directional_joy_motion(player.current_action_set, layer_key, action_name, player_number)
				if motion != InputActionDef.JoypadMotion.NONE:
					if direction.is_empty():
						return InputActionDef.joypad_motion_to_string(motion).to_lower()
					else:
						return "%s_%s"%[InputActionDef.joypad_motion_to_string(motion).to_lower(), direction]
			else: # Fallback to digital input
				var index: int
				match direction:
					"up": index = 0
					"down": index = 1
					"left": index = 2
					"right": index = 3
					_: index = 0 # Up is default for unspecified
				var button := remapper.get_remap_directional_joy_button(player.current_action_set,layer_key, action_name, player_number)[index]
				if button != InputActionDef.JoypadButton.NONE:
					if direction.is_empty():
						return InputActionDef.joypad_button_to_string(button).to_lower()
					else:
						return "%s_%s"%[InputActionDef.joypad_button_to_string(button).to_lower(), direction]
	return "" # Couldn't resolve

## Returns the display glyph for last device, used by player.
func get_player_device_glyph(player_number: int) -> Texture2D:
	if player_number <= 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range to grab device glyph: %d" % player_number)
		return null
	var device := get_device(get_player(player_number).last_device)
	if device == null || device.glyph_map == null:
		return null
	return device.glyph_map.device_glyph

## Returns the name glyph for last device, used by player.
func get_player_device_string(player_number: int) -> StringName:
	if player_number <= 0 || player_number > InputRelay.MAX_PLAYERS:
		push_error("Player number out of range to grab device string: %d" % player_number)
		return &""
	var device := get_device(get_player(player_number).last_device)
	if device == null || device.glyph_map == null:
		return &""
	return device.name

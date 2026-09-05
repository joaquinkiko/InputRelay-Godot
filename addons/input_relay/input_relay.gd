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
		players[n].current_action_set = settings.default_action_set
	# Setup device connections
	Input.joy_connection_changed.connect(_joy_connection_changed)
	for id in Input.get_connected_joypads():
		_register_device(id)
	match OS.get_name(): # If on PC we should register Keyboard & Mouse
		"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD", "Web":
			_register_device(KEYBOARD_INDEX, "Keyboard & Mouse")
		_:
			pass
	# Setup remapper, and load initial mappings
	remapper = InputRelayMapper.new()
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
	remapper.refresh_mappings()

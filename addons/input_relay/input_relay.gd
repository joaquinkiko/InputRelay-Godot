## Global InputRelay manager
extends Node

## Emitted when device is connected
signal device_connected(id: int)
## Emitted when device is disconnected, may contain owner's number, or 0 for no owner
signal device_disconnected(id: int, owner: int)

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
			_register_device(-1, "Keyboard & Mouse")
		_:
			pass
	# Setup remapper, and load initial mappings
	remapper = InputRelayMapper.new()
	remapper.refresh_mappings()

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

func assign_device(device_id: int, player_number: int) -> void:
	var device := get_device(device_id)
	var player := get_player(player_number)
	if device == null || player == null:
		push_error("Passed invalid player or device number for device assignment")
	if device.player != null:
		unassign_device(device_id, device.player.number)
	player.devices.append(device)
	device.player = player

func unassign_device(device_id: int, player_number: int) -> void:
	var device := get_device(device_id)
	var player := get_player(player_number)
	if device == null || player == null:
		push_error("Passed invalid player or device number for device unassignment")
	if device.player == player:
		device.player == null
	if player.devices.has(device):
		player.devices.erase(device)

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

func device_is_assigned(device_id: int) -> bool:
	var device := get_device(device_id)
	return device != null && device.player != null

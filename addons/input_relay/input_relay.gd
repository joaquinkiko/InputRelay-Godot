## Global InputRelay manager
extends Node

## All connected [InputRelayDevice]s
var devices: Array[InputRelayDevice]
## All [InputRelayPlayer]s
var players: Array[InputRelayPlayer]
## All [InputActionSet]s sets, sorted by name
var action_sets: Dictionary[StringName, InputActionSet]

func _ready() -> void:
	# Setup device connections
	Input.joy_connection_changed.connect(_joy_connection_changed)
	for id in Input.get_connected_joypads():
		_register_device(id)
	devices.append(InputRelayDevice.new(-1, "Keyboard & Mouse"))

func _joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		_register_device(device_id)
	else:
		_unregister_device(device_id)

func _register_device(device_id: int) -> void:
	var device := InputRelayDevice.new(device_id, Input.get_joy_name(device_id))
	devices.append(device)

func _unregister_device(device_id: int) -> void:
	# Remove from player assignments
	for player in players:
		for device in player.devices.duplicate():
			if device.index == device_id:
				player.devices.erase(device)
	# Remove from devices
	for device in devices:
		if device.index == device_id:
			devices.erase(device_id)
			break

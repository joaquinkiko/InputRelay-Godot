## Represents a player/user to assign input devices to
class_name InputRelayPlayer extends RefCounted

## Player number (starts at 1)
var number: int
## Currently assigned devices
var devices: Array[InputRelayDevice]
## Color for use by gamepad lights
var color: Color:
	get: return _color
	set(value):
		_color = value
		for device in devices:
			if device.supports_lights():
				device.set_light(value)
var _color := Color.WHITE
## Key of currently active action set
var current_action_set: StringName
## Key(s) of currently active layers on action set
var current_action_layers: Array[StringName]
## Index of last device to receive input from owned devices
var last_device: int:
	get: return _last_device
	set(value):
		_last_device = value
		# Update mouse mode on change
		if !InputRelay.has_mouse_and_keyboard_assigned(number): return
		var sets := InputRelay.get_player_action_set_and_layers(number)
		if !sets.is_empty():
			sets.back().apply_mouse_mode(value != InputRelay.KEYBOARD_INDEX)
var _last_device: int = -1

func _init(new_number: int) -> void:
	self.number = new_number

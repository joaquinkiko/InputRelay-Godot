## Represents a player/user to assign input devices to
class_name InputRelayPlayer extends RefCounted

## Player number (starts at 1)
var number: int
## Currently assigned devices
var devices: Array[InputRelayDevice]
## Color for use by gamepad lights
var color := Color.WHITE
## Key of currently active action set
var current_action_set: StringName
## Key(s) of currently active layers on action set
var current_action_layers: Array[StringName]

func _init(new_number: int) -> void:
	self.number = new_number

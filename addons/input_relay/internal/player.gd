## Represents a player/user to assign input devices to
class_name InputRelayPlayer extends RefCounted

## Currently assigned devices
var devices: Array[InputRelayDevice]
## Color for use by gamepad lights
var color := Color.WHITE
## Key of currently active action set
var current_action_set: StringName
## Key(s) of currently active layers on action set
var current_action_layers: Array[StringName]

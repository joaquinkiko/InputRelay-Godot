## TextureRect that displays a glyph for an input action, updating when the
## player's device or remap changes. Set [member direction] for directional actions.
## If manually changing values at runtime, make sure to call [method refresh].
class_name InputGlyphRect extends TextureRect

enum Direction {
	NONE = -1,
	UP = 0,
	DOWN = 1,
	LEFT = 2,
	RIGHT = 3, 
	}

## Player to use as reference
@export_range(1, 8, 1, "or_greater") var player_number: int = 1
## Set key of action
@export var set_key: StringName
## Optional layer key of action
@export var layer_key: StringName
## Action key
@export var action_name: StringName
## Used for directional input, can use none for direction agnostic
@export var direction: Direction = Direction.NONE

func _ready() -> void:
	InputRelay.switch_current_device_type.connect(_player_switched_device)
	refresh()

func _player_switched_device(player: int, old_device: int, new_device: int) -> void:
	if player != player_number: return
	refresh()

## Rebuilds the displayed texture. Call manually after applying a remap.
func refresh() -> void:
	var player := InputRelay.get_player(player_number)
	if player == null:
		texture = null
		return
	var device := InputRelay.get_device(player.last_device)
	if device == null || device.glyph_map == null:
		texture = null
		return
	var input_name := _resolve_input_name(device)
	if input_name.is_empty():
		texture = null
		return
	texture = device.glyph_map.get("%s_glyph"%input_name)

## Resolves the enum name of the currently bound input, for glyph_map property lookup
func _resolve_input_name(device: InputRelayDevice) -> String:
	var is_keyboard := device.index == InputRelay.KEYBOARD_INDEX
	if direction == Direction.NONE:
		if is_keyboard:
			if InputRelay.remapper._find_action_def(set_key, layer_key, action_name) is InputActionDefStickPad:
				var motion := InputRelay.remapper.get_remap_directional_joy_motion(set_key, layer_key, action_name, player_number)
				if motion != InputActionDef.JoypadMotion.NONE:
					InputActionDef.joypad_motion_to_string(motion).to_lower()
			else: # Is button, not motion
				var button := InputRelay.remapper.get_remap_key_mouse(set_key, layer_key, action_name, player_number)
				if button != InputActionDef.MouseKeyButton.NONE:
					InputActionDef.mouse_key_button_to_string(button).to_lower()
		else: # Is joy
			if InputRelay.remapper._find_action_def(set_key, layer_key, action_name) is InputActionDefStickPad:
				var motion := InputRelay.remapper.get_remap_directional_joy_motion(set_key, layer_key, action_name, player_number)
				if motion != InputActionDef.JoypadMotion.NONE:
					return InputActionDef.joypad_motion_to_string(motion).to_lower()
			else: # Is button, not motion
				var button := InputRelay.remapper.get_remap_joy_button(set_key, layer_key, action_name, player_number)
				if button != InputActionDef.JoypadButton.NONE:
					return InputActionDef.joypad_button_to_string(button).to_lower()
	else:
		if is_keyboard:
			var button := InputRelay.remapper.get_remap_directional_key_mouse(set_key, layer_key, action_name, player_number)[direction]
			if button != InputActionDef.MouseKeyButton.NONE:
				InputActionDef.mouse_key_button_to_string(button).to_lower()
		else: # Is joy
			var button := InputRelay.remapper.get_remap_directional_joy_button(set_key, layer_key, action_name, player_number)[direction]
			if button != InputActionDef.JoypadButton.NONE:
				return InputActionDef.joypad_button_to_string(button).to_lower()
	return ""

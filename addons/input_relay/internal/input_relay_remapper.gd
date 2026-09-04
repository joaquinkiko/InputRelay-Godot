## Builds and refreshes InputMap actions from an InputRelay's players and settings
class_name InputRelayMapper extends RefCounted

## Directions generated for each [InputActionDefStickPad]
const _STICK_DIRECTIONS: Array[StringName] = [&"up", &"down", &"left", &"right"]

## Actions created by the last refresh_mappings(), so they can be cleared first
var _managed_actions: Array[StringName] = []

## Remaps configuration file
var remap_file: ConfigFile

## Path to save/load [member remap_file]
var remap_file_path: String

func _init() -> void:
	# Get remap path from project settings, and load settings if auto loading is enabled
	remap_file_path = ProjectSettings.get_setting("InputRelay/remap_save_load_path", "user://input_remaps.cfg")
	if ProjectSettings.get_setting("InputRelay/auto_save_load_remaps", true):
		load_remaps()

func _notification(what: int) -> void:
	# Auto-save remaps before deleting
	if what == NOTIFICATION_PREDELETE and ProjectSettings.get_setting("InputRelay/auto_save_load_remaps", true):
		save_remaps()

## Loads a [member remap_file] from [member remap_file_path]. Fails if path is empty.
func load_remaps() -> void:
	if remap_file_path.is_empty():
		push_error("No remap_file_path defined, unable to load")
		return
	remap_file.load(remap_file_path)

## Saves a [member remap_file] from [member remap_file_path]. Fails if path is empty.
func save_remaps() -> void:
	if remap_file_path.is_empty():
		push_error("No remap_file_path defined, unable to save")
		return
	remap_file.save(remap_file_path)

## Rebuilds InputMap actions from every player's active action set + layers.
## These are labeled as "[action][player_number]" for non-directional, and
## "[action][direction][player_number]" for directional input.
## Player 1 additionally gets un-numbered actions for singleplayer convenience.
func refresh_mappings() -> void:
	# Clear actions that weren't manually setup
	for action_name in _managed_actions:
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)
	_managed_actions.clear()
	
	for player in InputRelay.players:
		var action_set: InputActionSet = InputRelay.settings.action_sets.get(player.current_action_set)
		if action_set == null:
			continue
		var actions: Dictionary[StringName, InputActionDef] = action_set.actions.duplicate()
		for layer_name in player.current_action_layers:
			var layer: InputActionSet = action_set.layers.get(layer_name)
			if layer == null:
				continue
			for action_key in layer.actions:
				actions[action_key] = layer.actions[action_key]
		
		for action_key in actions:
			_map_action(action_key, actions[action_key], player)

## Creates the InputMap action(s) for a single [InputActionDef]
func _map_action(action_name: StringName, action_def: InputActionDef, player: InputRelayPlayer) -> void:
	if action_def is InputActionDefStickPad:
		for direction in _STICK_DIRECTIONS: # Need to map multiple directions
			_map_stick_direction(action_name, direction, action_def, player)
		return
	# Suffix is typically player number, though player 1 also uses blank, or no suffix
	for suffix in _action_suffixes(player):
		var full_name := StringName("%s%s"%[action_name, suffix])
		InputMap.add_action(full_name)
		if action_def is InputActionDefAnalog:
			InputMap.action_set_deadzone(full_name, action_def.deadzone)
		_managed_actions.append(full_name)
		for device in player.devices:
			if device.index == -1:
				_add_key_mouse_event(full_name, action_def.get(&"mouse_key_button"), device.index)
			else:
				_add_joy_button_event(full_name, action_def.get(&"joy_button"), device.index)

## Registers one directional sub-action for a stick pad: "[name]_[direction][suffix]"
func _map_stick_direction(action_name: StringName, direction: StringName, stick_pad: InputActionDefStickPad, player: InputRelayPlayer) -> void:
	var mouse_key_button: InputActionDef.MouseKeyButton = stick_pad.get("%s_mouse_key_button"%direction)
	var axes := InputActionDef.joypad_motion_to_joy_axes(stick_pad.joy_motion)
	var is_horizontal := direction == &"left" || direction == &"right"
	var invert := stick_pad.invert_x if is_horizontal else stick_pad.invert_y
	var negative := direction == &"left" || direction == &"up"
	var sign := -1.0 if negative != invert else 1.0
	
	for suffix in _action_suffixes(player):
		var full_name := StringName("%s_%s%s" % [action_name, direction, suffix])
		InputMap.add_action(full_name)
		InputMap.action_set_deadzone(full_name, stick_pad.deadzone)
		_managed_actions.append(full_name)
		for device in player.devices:
			if device.index == -1:
				_add_key_mouse_event(full_name, mouse_key_button, device.index)
			elif axes.size() == 2:
				var event := InputEventJoypadMotion.new()
				event.device = device.index
				event.axis = axes[0] if is_horizontal else axes[1]
				event.axis_value = sign
				InputMap.action_add_event(full_name, event)

## Suffixes to build for a player: numbered always, plus "" for player 1
func _action_suffixes(player: InputRelayPlayer) -> Array[String]:
	var suffixes: Array[String] = [str(player.number)]
	if player.number == 1:
		suffixes.append("")
	return suffixes

## Adds a keyboard or mouse event for a [MouseKeyButton], skipping NONE
func _add_key_mouse_event(action: StringName, button: InputActionDef.MouseKeyButton, device_id: int) -> void:
	if button == InputActionDef.MouseKeyButton.NONE:
		return
	if InputActionDef.is_mouse_button(button):
		var event := InputEventMouseButton.new()
		event.device = device_id
		event.button_index = InputActionDef.mouse_key_button_to_mouse_button(button)
		InputMap.action_add_event(action, event)
	else: # Keyboard key
		var event := InputEventKey.new()
		event.device = device_id
		# Use physical_keycode, so key is layout agnostic
		event.physical_keycode = InputActionDef.mouse_key_button_to_key(button)
		InputMap.action_add_event(action, event)

## Adds a gamepad button or trigger-axis event for a [JoypadButton], skipping NONE
func _add_joy_button_event(action: StringName, button: InputActionDef.JoypadButton, device_id: int) -> void:
	if button == InputActionDef.JoypadButton.NONE:
		return
	if InputActionDef.is_axis_button(button):
		var event := InputEventJoypadMotion.new()
		event.device = device_id
		event.axis = InputActionDef.joypad_button_to_joy_axis(button)
		event.axis_value = 1
		InputMap.action_add_event(action, event)
	else: # Joypad button
		var event := InputEventJoypadButton.new()
		event.device = device_id
		event.button_index = InputActionDef.joypad_button_to_joy_button(button)
		InputMap.action_add_event(action, event)

## Finds the InputActionDef for a set/layer/action path, or null if not found
func _find_action_def(set_key: StringName, layer: StringName, action: StringName) -> InputActionDef:
	var action_set: InputActionSet = InputRelay.settings.action_sets.get(set_key)
	if action_set == null:
		return null
	if not String(layer).is_empty():
		action_set = action_set.layers.get(layer)
		if action_set == null:
			return null
	return action_set.actions.get(action)

## Validates non-empty set/action and player number range
func _validate_remap_args(set_key: StringName, action: StringName, player: int) -> bool:
	if String(set_key).is_empty():
		push_error("Remap requires a non-empty set")
		return false
	if String(action).is_empty():
		push_error("Remap requires a non-empty action")
		return false
	if player < 0 || player > InputRelay.MAX_PLAYERS:
		push_error("Remap player number out of range: %d" % player)
		return false
	return true

## Validates args and confirms the target action exists, returning its def or null
func _validate_remap_target(set_key: StringName, layer: StringName, action: StringName, player: int) -> InputActionDef:
	if not _validate_remap_args(set_key, action, player):
		return null
	var action_def := _find_action_def(set_key, layer, action)
	if action_def == null:
		push_error("No action found at %s" % _remap_key(set_key, layer, action))
	return action_def

## Builds the remap_file section for a player (0 = all players) and remap type
func _remap_section(player: int, remap_type: String) -> String:
	return "%s_%s" % ["Global" if player == 0 else "Player%d" % player, remap_type]

## Builds the remap_file key for a set/layer/action path. Layer is omitted when empty
func _remap_key(set_key: StringName, layer: StringName, action: StringName) -> String:
	if String(layer).is_empty():
		return "%s/%s" % [set_key, action]
	return "%s/%s/%s" % [set_key, layer, action]

func _remap_write(remap_type: String, set_key: StringName, layer: StringName, action: StringName, player: int, value: Variant) -> void:
	remap_file.set_value(_remap_section(player, remap_type), _remap_key(set_key, layer, action), value)

func _remap_erase(remap_type: String, set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	remap_file.erase_section_key(_remap_section(player, remap_type), _remap_key(set_key, layer, action))

## Returns the stored value for a remap key, or default if unset
func _remap_read(remap_type: String, set_key: StringName, layer: StringName, action: StringName, player: int, default: Variant):
	var section := _remap_section(player, remap_type)
	var key := _remap_key(set_key, layer, action)
	if remap_file.has_section_key(section, key):
		return remap_file.get_value(section, key)
	return default

## Non-directional key/mouse remap setter
func remap_key_mouse(set_key: StringName, layer: StringName, action: StringName, player: int, new_value: InputActionDef.MouseKeyButton) -> void:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return
	if not (action_def is InputActionDefDigital || action_def is InputActionDefAnalog):
		push_error("Action at %s does not support key/mouse remapping" % _remap_key(set_key, layer, action))
		return
	if not InputActionDef.is_valid_mouse_key_button(new_value):
		push_error("Invalid MouseKeyButton value: %d" % new_value)
		return
	_remap_write("KeyMouse", set_key, layer, action, player, InputActionDef.mouse_key_button_to_string(new_value))

## Non-directional key/mouse remap eraser
func clear_remap_key_mouse(set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	if _validate_remap_target(set_key, layer, action, player) == null:
		return
	_remap_erase("KeyMouse", set_key, layer, action, player)

## Non-directional key/mouse remap getter. Falls back to default [InputActionDef] value
func get_remap_key_mouse(set_key: StringName, layer: StringName, action: StringName, player: int) -> InputActionDef.MouseKeyButton:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return InputActionDef.MouseKeyButton.NONE
	var value = _remap_read("KeyMouse", set_key, layer, action, player, null)
	if value != null:
		return InputActionDef.string_to_mouse_key_button(value)
	if action_def.get("mouse_key_button") != null:
		return action_def.get("mouse_key_button")
	return InputActionDef.MouseKeyButton.NONE

## Non-directional joy button remap setter
func remap_joy_button(set_key: StringName, layer: StringName, action: StringName, player: int, new_value: InputActionDef.JoypadButton) -> void:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return
	if not (action_def is InputActionDefDigital || action_def is InputActionDefAnalog):
		push_error("Action at %s does not support joy button remapping" % _remap_key(set_key, layer, action))
		return
	if not InputActionDef.is_valid_joypad_button(new_value):
		push_error("Invalid JoypadButton value: %d" % new_value)
		return
	_remap_write("Joy", set_key, layer, action, player, InputActionDef.joypad_button_to_string(new_value))

## Non-directional joy button remap eraser
func clear_remap_joy_button(set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	if _validate_remap_target(set_key, layer, action, player) == null:
		return
	_remap_erase("Joy", set_key, layer, action, player)

## Non-directional joy button remap getter. Falls back to default [InputActionDef] value
func get_remap_joy_button(set_key: StringName, layer: StringName, action: StringName, player: int) -> InputActionDef.JoypadButton:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return InputActionDef.JoypadButton.NONE
	var value = _remap_read("Joy", set_key, layer, action, player, null)
	if value != null:
		return InputActionDef.string_to_joypad_button(value)
	if action_def.get("joy_button") != null:
		return action_def.get("joy_button")
	return InputActionDef.JoypadButton.NONE

## Stick pad's joy motion remap setter
func remap_directional_joy_motion(set_key: StringName, layer: StringName, action: StringName, player: int, new_value: InputActionDef.JoypadMotion) -> void:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return
	if not (action_def is InputActionDefStickPad):
		push_error("Action at %s is not a Stick Pad action" % _remap_key(set_key, layer, action))
		return
	if not InputActionDef.is_valid_joypad_motion(new_value):
		push_error("Invalid JoypadMotion value: %d" % new_value)
		return
	_remap_write("Joy", set_key, layer, action, player, InputActionDef.joypad_motion_to_string(new_value))

## Stick pad's joy motion remap eraser
func clear_remap_directional_joy_motion(set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	if _validate_remap_target(set_key, layer, action, player) == null:
		return
	_remap_erase("Joy", set_key, layer, action, player)

## Stick pad's joy motion remap getter. Falls back to default [InputActionDef] value
func get_remap_directional_joy_motion(set_key: StringName, layer: StringName, action: StringName, player: int) -> InputActionDef.JoypadMotion:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return InputActionDef.JoypadMotion.NONE
	var value = _remap_read("Joy", set_key, layer, action, player, null)
	if value != null:
		return InputActionDef.string_to_joypad_motion(value)
	if action_def is InputActionDefStickPad:
		return action_def.joy_motion
	return InputActionDef.JoypadMotion.NONE

## Dpad's 4-way joy button remap setter. Pass -1 for any direction to leave it unchanged
func remap_directional_joy_button(set_key: StringName, layer: StringName, action: StringName, player: int, up: int, down: int, left: int, right: int) -> void:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return
	if not (action_def is InputActionDefDpad):
		push_error("Action at %s is not a Dpad action" % _remap_key(set_key, layer, action))
		return
	var default_values := [
		InputActionDef.joypad_button_to_string(action_def.up_joy_button), InputActionDef.joypad_button_to_string(action_def.down_joy_button),
		InputActionDef.joypad_button_to_string(action_def.left_joy_button), InputActionDef.joypad_button_to_string(action_def.right_joy_button),
	]
	var values: Array = _remap_read("Joy", set_key, layer, action, player, default_values).duplicate()
	var new_values := [up, down, left, right]
	for i in 4:
		if new_values[i] == -1:
			continue
		if not InputActionDef.is_valid_joypad_button(new_values[i]):
			push_error("Invalid JoypadButton value: %d" % new_values[i])
			return
		values[i] = InputActionDef.joypad_button_to_string(new_values[i])
	_remap_write("Joy", set_key, layer, action, player, values)

## Dpad's 4-way joy button remap eraser
func clear_remap_directional_joy_button(set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	if _validate_remap_target(set_key, layer, action, player) == null:
		return
	_remap_erase("Joy", set_key, layer, action, player)

## ## Dpad's 4-way joy button remap getter. Returns [up, down, left, right]. Falls back to default [InputActionDef] value
func get_remap_directional_joy_button(set_key: StringName, layer: StringName, action: StringName, player: int) -> Array[InputActionDef.JoypadButton]:
	var default_result: Array[InputActionDef.JoypadButton] = [InputActionDef.JoypadButton.NONE, InputActionDef.JoypadButton.NONE, InputActionDef.JoypadButton.NONE, InputActionDef.JoypadButton.NONE]
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return default_result
	var values = _remap_read("Joy", set_key, layer, action, player, null)
	if values != null:
		var result: Array[InputActionDef.JoypadButton] = []
		for value in values:
			result.append(InputActionDef.string_to_joypad_button(value))
		return result
	if action_def is InputActionDefDpad:
		return [action_def.up_joy_button, action_def.down_joy_button, action_def.left_joy_button, action_def.right_joy_button]
	return default_result

## Stick pad/Dpad's 4-way key/mouse remap setter. Pass -1 for any direction to leave it unchanged
func remap_directional_key_mouse(set_key: StringName, layer: StringName, action: StringName, player: int, up: int, down: int, left: int, right: int) -> void:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return
	if not (action_def is InputActionDefStickPad || action_def is InputActionDefDpad):
		push_error("Action at %s does not support directional key/mouse remapping" % _remap_key(set_key, layer, action))
		return
	var default_values := [
		InputActionDef.mouse_key_button_to_string(action_def.up_mouse_key_button), InputActionDef.mouse_key_button_to_string(action_def.down_mouse_key_button),
		InputActionDef.mouse_key_button_to_string(action_def.left_mouse_key_button), InputActionDef.mouse_key_button_to_string(action_def.right_mouse_key_button),
	]
	var values: Array = _remap_read("KeyMouse", set_key, layer, action, player, default_values).duplicate()
	var new_values := [up, down, left, right]
	for i in 4:
		if new_values[i] == -1:
			continue
		if not InputActionDef.is_valid_mouse_key_button(new_values[i]):
			push_error("Invalid MouseKeyButton value: %d" % new_values[i])
			return
		values[i] = InputActionDef.mouse_key_button_to_string(new_values[i])
	_remap_write("KeyMouse", set_key, layer, action, player, values)

## Stick pad/Dpad's 4-way key/mouse remap eraser
func clear_remap_directional_key_mouse(set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	if _validate_remap_target(set_key, layer, action, player) == null:
		return
	_remap_erase("KeyMouse", set_key, layer, action, player)

## Stick pad/Dpad's 4-way key/mouse remap getter. Returns [up, down, left, right]. Falls back to default [InputActionDef] value
func get_remap_directional_key_mouse(set_key: StringName, layer: StringName, action: StringName, player: int) -> Array[InputActionDef.MouseKeyButton]:
	var default_result: Array[InputActionDef.MouseKeyButton] = [InputActionDef.MouseKeyButton.NONE, InputActionDef.MouseKeyButton.NONE, InputActionDef.MouseKeyButton.NONE, InputActionDef.MouseKeyButton.NONE]
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return default_result
	var values = _remap_read("KeyMouse", set_key, layer, action, player, null)
	if values != null:
		var result: Array[InputActionDef.MouseKeyButton] = []
		for value in values:
			result.append(InputActionDef.string_to_mouse_key_button(value))
		return result
	if action_def is InputActionDefStickPad || action_def is InputActionDefDpad:
		return [action_def.up_mouse_key_button, action_def.down_mouse_key_button, action_def.left_mouse_key_button, action_def.right_mouse_key_button]
	return default_result

## Stick pad user mouse motion setter
func remap_update_mouse_motion(set_key: StringName, layer: StringName, action: StringName, player: int, new_value: bool) -> void:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return
	if not (action_def is InputActionDefStickPad):
		push_error("Action at %s is not a Stick Pad action" % _remap_key(set_key, layer, action))
		return
	_remap_write("UseMouse", set_key, layer, action, player, new_value)

## Stick pad user mouse motion eraser
func clear_remap_update_mouse_motion(set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	if _validate_remap_target(set_key, layer, action, player) == null:
		return
	_remap_erase("UseMouse", set_key, layer, action, player)

## Stick pad user mouse motion getter. Falls back to default [InputActionDef] value
func get_remap_update_mouse_motion(set_key: StringName, layer: StringName, action: StringName, player: int) -> bool:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return false
	var value = _remap_read("UseMouse", set_key, layer, action, player, null)
	if value != null:
		return value
	if action_def is InputActionDefStickPad:
		return action_def.mouse_motion
	return false

## Stick pad sensitivity setter
func remap_update_sensitivity(set_key: StringName, layer: StringName, action: StringName, player: int, new_value: float) -> void:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return
	if not (action_def is InputActionDefStickPadVelocity):
		push_error("Action at %s is not a Stick Pad Velocity action" % _remap_key(set_key, layer, action))
		return
	if new_value < 0.0:
		push_error("Sensitivity must be >= 0.0")
		return
	_remap_write("Sensitivity", set_key, layer, action, player, new_value)

## Stick pad sensitivity eraser
func clear_remap_update_sensitivity(set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	if _validate_remap_target(set_key, layer, action, player) == null:
		return
	_remap_erase("Sensitivity", set_key, layer, action, player)

## Stick pad sensitivity getter. Falls back to default [InputActionDef] value
func get_remap_update_sensitivity(set_key: StringName, layer: StringName, action: StringName, player: int) -> float:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return -1.0
	var value = _remap_read("Sensitivity", set_key, layer, action, player, null)
	if value != null:
		return value
	if action_def is InputActionDefStickPadVelocity:
		return action_def.sensitivity
	return -1.0

## Stick pad and analog deadzone setter
func remap_update_deadzone(set_key: StringName, layer: StringName, action: StringName, player: int, new_value: float) -> void:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return
	if not (action_def is InputActionDefAnalog || action_def is InputActionDefStickPad):
		push_error("Action at %s does not support deadzone remapping" % _remap_key(set_key, layer, action))
		return
	if new_value < 0.0 || new_value > 1.0:
		push_error("Deadzone must be between 0.0 and 1.0")
		return
	_remap_write("Deadzone", set_key, layer, action, player, new_value)

## Stick pad and analog deadzone eraser
func clear_remap_update_deadzone(set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	if _validate_remap_target(set_key, layer, action, player) == null:
		return
	_remap_erase("Deadzone", set_key, layer, action, player)

## Stick pad and analog deadzone getter. Falls back to default [InputActionDef] value
func get_remap_update_deadzone(set_key: StringName, layer: StringName, action: StringName, player: int) -> float:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return -1.0
	var value = _remap_read("Deadzone", set_key, layer, action, player, null)
	if value != null:
		return value
	if action_def.get("deadzone") != null:
		return action_def.get("deadzone")
	return -1.0

## Invert x configuration setter
func remap_update_invert_x(set_key: StringName, layer: StringName, action: StringName, player: int, new_value: bool) -> void:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return
	if not (action_def is InputActionDefStickPad):
		push_error("Action at %s is not a Stick Pad action" % _remap_key(set_key, layer, action))
		return
	_remap_write("InvertX", set_key, layer, action, player, new_value)

## Invert x configuration eraser
func clear_remap_update_invert_x(set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	if _validate_remap_target(set_key, layer, action, player) == null:
		return
	_remap_erase("InvertX", set_key, layer, action, player)

## Invert x configuration getter. Falls back to default [InputActionDef] value
func get_remap_update_invert_x(set_key: StringName, layer: StringName, action: StringName, player: int) -> bool:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return false
	var value = _remap_read("InvertX", set_key, layer, action, player, null)
	if value != null:
		return value
	if action_def is InputActionDefStickPad:
		return action_def.invert_x
	return false

## Invert y configuration setter
func remap_update_invert_y(set_key: StringName, layer: StringName, action: StringName, player: int, new_value: bool) -> void:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return
	if not (action_def is InputActionDefStickPad):
		push_error("Action at %s is not a Stick Pad action" % _remap_key(set_key, layer, action))
		return
	_remap_write("InvertY", set_key, layer, action, player, new_value)

## Invert y configuration eraser
func clear_remap_update_invert_y(set_key: StringName, layer: StringName, action: StringName, player: int) -> void:
	if _validate_remap_target(set_key, layer, action, player) == null:
		return
	_remap_erase("InvertY", set_key, layer, action, player)

## Invert y configuration getter. Falls back to default [InputActionDef] value
func get_remap_update_invert_y(set_key: StringName, layer: StringName, action: StringName, player: int) -> bool:
	var action_def := _validate_remap_target(set_key, layer, action, player)
	if action_def == null:
		return false
	var value = _remap_read("InvertY", set_key, layer, action, player, null)
	if value != null:
		return value
	if action_def is InputActionDefStickPad:
		return action_def.invert_y
	return false

## Clears all remaps for specified player, or 0 for only global remaps (specific player remaps will remain)
func clear_remaps(player: int) -> void:
	if player < 0 || player > InputRelay.MAX_PLAYERS:
		push_error("Remap player number out of range: %d" % player)
		return
	for section in remap_file.get_sections().duplicate():
		if player == 0 and section.begins_with("Global"):
			remap_file.erase_section(section)
			continue
		elif section.begins_with("Player%s"%player):
			remap_file.erase_section(section)

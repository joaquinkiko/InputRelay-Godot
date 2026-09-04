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

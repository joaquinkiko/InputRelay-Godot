## Configures available set of input actions for a particular context
class_name InputActionSet extends Resource

enum MouseModes {
	VISIBLE,
	HIDDEN,
	CONFINED,
	CONFINED_VISIBLE,
	CAPTURED,
}

## Alternate localizations for set name
@export var localizations: Dictionary[StringName, StringName]

## Additional layers that can be activated ontop of this set, sorted by name.
## These will be ignored on layers (only top level sets will use this.
@export var layers: Dictionary[StringName, InputActionSet]

## These flags control how the mouse should appear when this set is active for
## a mouse and keyboard player, and they're using mouse and keyboard.
@export var mouse_mode_keyboard: Input.MouseMode = Input.MouseMode.MOUSE_MODE_VISIBLE

## These flags control how the mouse should appear when this set is active for
## a mouse and keyboard player and they're using a joypad.
@export var mouse_mode_joy: Input.MouseMode = Input.MouseMode.MOUSE_MODE_CAPTURED

## Available actions for this set, sorted by name
@export var actions: Dictionary[StringName, InputActionDef]

func sanitize_keys(is_layer := false) -> void:
	# Enfoce no '+' and lowercase for keys for compatibility with SteamInput setup
	for key: StringName in actions:
		if key != String(key).to_lower():
			push_error("Action Names should be lowercase!")
			actions[StringName(key.to_lower())] = actions[key]
			actions.erase(key)
	for key: StringName in actions:
		if key != String(key).replace('+', ' '):
			push_error("Action Names should not include '+' character, replacing with ' '!")
			actions[StringName(key.replace('+', ' '))] = actions[key]
			actions.erase(key)
	for key: StringName in layers:
		if key != String(key).to_lower():
			push_error("Action layers should be lowercase!")
			layers[StringName(key.to_lower())] = layers[key]
			layers.erase(key)
	for key: StringName in layers:
		if key != String(key).replace('+', ' '):
			push_error("Action layers should not include '+' character, replacing with ' '!")
			layers[StringName(key.replace('+', ' '))] = layers[key]
			layers.erase(key)
	if !is_layer: # Prevents accidental recursive loop
		for key in layers:
			layers[key].sanitize_keys(true)

func apply_mouse_mode(using_joy: bool) -> void:
	var mode: Input.MouseMode
	if using_joy: mode = mouse_mode_joy
	else: mode = mouse_mode_keyboard
	Input.mouse_mode = mode

## Button that remaps an action when pressed. Displays the current binding using
## the translation keys built by [InputRelayMapper], or a prompt while awaiting input.
class_name ButtonRemapper extends Button

## Emitted when the button begins listening for input
signal remap_started
## Emitted when listening ends. [param applied] is false on cancel or timeout.
signal remap_finished(applied: bool)

## Player to remap. 0 remaps every player, and displays player 1's binding.
@export_range(0, 8, 1, "or_greater") var player_number: int = 1
@export var set_key: StringName
## Optional layer key of action
@export var layer_key: StringName
@export var action_name: StringName
## Required for directional actions, ignored otherwise
@export var direction: InputGlyphRect.Direction = InputGlyphRect.Direction.NONE
@export_group("Text")
## Shown while awaiting input
@export var prompt_text: String = "Press any input..."
## Shown when the action has no binding
@export var unbound_text: String = "Unbound"
@export_group("Remap")
@export var timeout_seconds: float = 5.0
@export var escape_key_mouse_buttons: Array[InputActionDef.MouseKeyButton] = InputRelay._DEFAULT_REMAP_ESCAPE_KEYBOARD.duplicate()
@export var escape_joy_buttons: Array[InputActionDef.JoypadButton] = InputRelay._DEFAULT_REMAP_ESCAPE_JOY.duplicate()

var _is_remapping := false

func _ready() -> void:
	InputRelay.switch_current_device_type.connect(_queue_refresh.unbind(3))
	InputRelay.remapper.refreshed_mappings.connect(_queue_refresh)
	_queue_refresh()

func _pressed() -> void:
	if _is_remapping:
		return
	_is_remapping = true
	text = prompt_text
	remap_started.emit()
	var applied: bool = await _run_remap()
	_is_remapping = false
	if applied:
		InputRelay.remapper.refresh_mappings()
		InputRelay.remapper.refresh_translations()
	refresh()
	remap_finished.emit(applied)

## Rebuilds the displayed text. Call manually if values change at runtime.
func refresh() -> void:
	if _is_remapping:
		return
	var key := _translation_key()
	var display := tr(key)
	text = unbound_text if display == key else display

## Deferred, so translations finish rebuilding before we read them
func _queue_refresh() -> void:
	refresh.call_deferred()

func _run_remap() -> bool:
	var action_def := InputRelay.remapper._find_action_def(set_key, layer_key, action_name)
	if action_def == null:
		push_error("ButtonRemapper found no action for %s/%s/%s" % [set_key, layer_key, action_name])
		return false
	if action_def is InputActionDefDirectional:
		match direction:
			InputGlyphRect.Direction.UP:
				return await InputRelay.remap_dpad_up_await(set_key, layer_key, action_name,
					player_number, timeout_seconds, escape_key_mouse_buttons, escape_joy_buttons)
			InputGlyphRect.Direction.DOWN:
				return await InputRelay.remap_dpad_down_await(set_key, layer_key, action_name,
					player_number, timeout_seconds, escape_key_mouse_buttons, escape_joy_buttons)
			InputGlyphRect.Direction.LEFT:
				return await InputRelay.remap_dpad_left_await(set_key, layer_key, action_name,
					player_number, timeout_seconds, escape_key_mouse_buttons, escape_joy_buttons)
			InputGlyphRect.Direction.RIGHT:
				return await InputRelay.remap_dpad_right_await(set_key, layer_key, action_name,
					player_number, timeout_seconds, escape_key_mouse_buttons, escape_joy_buttons)
		push_error("ButtonRemapper needs a direction for directional action %s"%action_name)
		return false
	return await InputRelay.remap_button_await(set_key, layer_key, action_name,
		player_number, timeout_seconds, escape_key_mouse_buttons, escape_joy_buttons)

## Builds the translation key, matching the keys made in refresh_translations
func _translation_key() -> String:
	var key := "INPUT_%s" % String(action_name).to_upper()
	if direction != InputGlyphRect.Direction.NONE:
		key += "_%s" % ["UP", "DOWN", "LEFT", "RIGHT"][direction]
	if player_number > 1:
		key += str(player_number)
	return key

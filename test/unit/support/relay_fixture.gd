extends GutTest

const SET_KEY := &"gameplay"
const PAD_ID := 60
const SECOND_PAD_ID := 61

var settings: InputRelaySettings
var keyboard: InputRelayDevice
var pad: InputRelayDevice
var second_pad: InputRelayDevice
var player_one: InputRelayPlayer
var player_two: InputRelayPlayer

var saved_settings: InputRelaySettings
var saved_players: Array
var saved_devices: Array
var saved_max_players: int
var saved_remap_file: ConfigFile

func before_each() -> void:
	saved_settings = InputRelay.settings
	saved_players = InputRelay.players.duplicate()
	saved_devices = InputRelay.devices.duplicate()
	saved_max_players = InputRelay.MAX_PLAYERS
	saved_remap_file = InputRelay.remapper.remap_file
	
	settings = InputRelaySettings.new()
	settings.mouse_keyboard_glyph_map = DeviceGlyphMapKeyboard.new()
	settings.generic_glyph_map = DeviceGlyphMapGamepad.new()
	settings.xbox_glyph_map = DeviceGlyphMapGamepad.new()
	settings.dualshock_glyph_map = DeviceGlyphMapGamepad.new()
	settings.nintendo_pro_glyph_map = DeviceGlyphMapGamepad.new()
	settings.action_sets[SET_KEY] = _build_action_set()
	settings.default_action_set = SET_KEY
	
	keyboard = InputRelayDevice.new(InputRelay.KEYBOARD_INDEX, "Keyboard & Mouse", settings)
	pad = InputRelayDevice.new(PAD_ID, "Xbox Pad", settings)
	second_pad = InputRelayDevice.new(SECOND_PAD_ID, "Xbox Pad 2", settings)
	player_one = _make_player(1, [keyboard, pad], InputRelay.KEYBOARD_INDEX)
	player_two = _make_player(2, [second_pad], SECOND_PAD_ID)
	
	InputRelay.settings = settings
	InputRelay.MAX_PLAYERS = 2
	InputRelay.players.assign([player_one, player_two])
	InputRelay.devices.assign([keyboard, pad, second_pad])
	InputRelay.remapper.remap_file = ConfigFile.new()

func after_each() -> void:
	InputRelay.remapper.remap_file = saved_remap_file
	InputRelay.settings = saved_settings
	InputRelay.players.assign(saved_players)
	InputRelay.devices.assign(saved_devices)
	InputRelay.MAX_PLAYERS = saved_max_players
	InputRelay.remapper.refresh_mappings()
	InputRelay.remapper.refresh_translations()

func _make_player(number: int, owned: Array, last_device: int) -> InputRelayPlayer:
	var player := InputRelayPlayer.new(number)
	for device in owned:
		player.devices.append(device)
		device.player = player
	player.current_action_set = SET_KEY
	player.last_device = last_device
	return player

func _build_action_set() -> InputActionSet:
	var action_set := InputActionSet.new()
	var jump := InputActionDefDigital.new()
	jump.mouse_key_button = InputActionDef.MouseKeyButton.SPACE
	jump.joy_button = InputActionDef.JoypadButton.SOUTH
	action_set.actions[&"test_jump"] = jump
	var move := InputActionDefStickPad.new()
	move.joy_motion = InputActionDef.JoypadMotion.LEFT_STICK
	move.up_mouse_key_button = InputActionDef.MouseKeyButton.W
	move.up_joy_button = InputActionDef.JoypadButton.DPAD_UP
	action_set.actions[&"test_move"] = move
	var look := InputActionDefStickPadVelocity.new()
	look.joy_motion = InputActionDef.JoypadMotion.RIGHT_STICK
	look.mouse_motion = true
	action_set.actions[&"test_look"] = look
	var directional := InputActionDefDirectional.new()
	directional.left_mouse_key_button = InputActionDef.MouseKeyButton.LEFT
	directional.left_joy_button = InputActionDef.JoypadButton.DPAD_LEFT
	action_set.actions[&"test_pad"] = directional
	var layer := InputActionSet.new()
	var confirm := InputActionDefDigital.new()
	confirm.mouse_key_button = InputActionDef.MouseKeyButton.ENTER
	confirm.joy_button = InputActionDef.JoypadButton.EAST
	layer.actions[&"test_confirm"] = confirm
	action_set.layers[&"menu"] = layer
	return action_set

func _joy_event(device_id: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	return event

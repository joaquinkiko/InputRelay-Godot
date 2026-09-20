extends GutTest

const SET_KEY := &"gameplay"
const PAD_ID := 60
const SECOND_PAD_ID := 61
const SPARE_PAD_ID := 62

class StubDevice extends InputRelayDevice:
	var vibrate_calls: Array[Vector3] = []
	var stop_calls := 0
	var vibrating := false

	func _init(device_id: int) -> void:
		super(device_id, "Stub", InputRelaySettings.new())
		feature_flags = Features.HAPTIC

	func vibrate(weak_motor: float, strong_motor: float, duration: float) -> void:
		vibrate_calls.append(Vector3(weak_motor, strong_motor, duration))

	func stop_vibrating() -> void:
		stop_calls += 1

	func is_vibrating() -> bool:
		return vibrating

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
var saved_mouse_mode: Input.MouseMode
var saved_auto_keyboard: Variant
var saved_auto_first: Variant

func before_each() -> void:
	saved_settings = InputRelay.settings
	saved_players = InputRelay.players.duplicate()
	saved_devices = InputRelay.devices.duplicate()
	saved_max_players = InputRelay.MAX_PLAYERS
	saved_remap_file = InputRelay.remapper.remap_file
	saved_mouse_mode = Input.mouse_mode
	saved_auto_keyboard = ProjectSettings.get_setting("InputRelay/player_1_auto_assign_keyboard", true)
	saved_auto_first = ProjectSettings.get_setting("InputRelay/player_1_auto_assign_first_device", true)
	ProjectSettings.set_setting("InputRelay/player_1_auto_assign_keyboard", true)
	ProjectSettings.set_setting("InputRelay/player_1_auto_assign_first_device", true)
	
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
	player_one = InputRelayPlayer.new(1)
	player_two = InputRelayPlayer.new(2)
	_assign(keyboard, player_one)
	_assign(pad, player_one)
	_assign(second_pad, player_two)
	for player in [player_one, player_two]:
		player.current_action_set = SET_KEY
	player_one.last_device = InputRelay.KEYBOARD_INDEX
	player_two.last_device = SECOND_PAD_ID
	
	InputRelay.settings = settings
	InputRelay.MAX_PLAYERS = 2
	InputRelay.players.assign([player_one, player_two])
	InputRelay.devices.assign([keyboard, pad, second_pad])
	InputRelay.remapper.remap_file = ConfigFile.new()
	InputRelay.player_awaiting_assignment = 0
	InputRelay.last_player_input = 0
	InputRelay._toggled_actions.clear()
	InputRelay._mouse_axis = Vector2.ZERO

func after_each() -> void:
	for action_name in InputRelay.remapper._managed_actions:
		if InputMap.has_action(action_name):
			Input.action_release(action_name)
	InputRelay.remapper.remap_file = saved_remap_file
	InputRelay.settings = saved_settings
	InputRelay.players.assign(saved_players)
	InputRelay.devices.assign(saved_devices)
	InputRelay.MAX_PLAYERS = saved_max_players
	InputRelay.player_awaiting_assignment = 0
	InputRelay._toggled_actions.clear()
	InputRelay._mouse_axis = Vector2.ZERO
	ProjectSettings.set_setting("InputRelay/player_1_auto_assign_keyboard", saved_auto_keyboard)
	ProjectSettings.set_setting("InputRelay/player_1_auto_assign_first_device", saved_auto_first)
	Input.mouse_mode = saved_mouse_mode
	InputRelay.remapper.refresh_mappings()
	InputRelay.remapper.refresh_translations()

func _assign(device: InputRelayDevice, player: InputRelayPlayer) -> void:
	player.devices.append(device)
	device.player = player

func _build_action_set() -> InputActionSet:
	var action_set := InputActionSet.new()
	var jump := InputActionDefDigital.new()
	jump.mouse_key_button = InputActionDef.MouseKeyButton.SPACE
	jump.joy_button = InputActionDef.JoypadButton.SOUTH
	action_set.actions[&"test_jump"] = jump
	var move := InputActionDefStickPad.new()
	move.joy_motion = InputActionDef.JoypadMotion.LEFT_STICK
	move.up_mouse_key_button = InputActionDef.MouseKeyButton.W
	move.down_mouse_key_button = InputActionDef.MouseKeyButton.S
	move.left_mouse_key_button = InputActionDef.MouseKeyButton.A
	move.right_mouse_key_button = InputActionDef.MouseKeyButton.D
	action_set.actions[&"test_move"] = move
	var look := InputActionDefStickPadVelocity.new()
	look.joy_motion = InputActionDef.JoypadMotion.RIGHT_STICK
	look.mouse_motion = true
	look.sensitivity = 2.0
	action_set.actions[&"test_look"] = look
	var directional := InputActionDefDirectional.new()
	directional.up_joy_button = InputActionDef.JoypadButton.DPAD_UP
	directional.down_joy_button = InputActionDef.JoypadButton.DPAD_DOWN
	directional.left_joy_button = InputActionDef.JoypadButton.DPAD_LEFT
	directional.right_joy_button = InputActionDef.JoypadButton.DPAD_RIGHT
	action_set.actions[&"test_pad"] = directional
	var layer := InputActionSet.new()
	var layer_jump := InputActionDefDigital.new()
	layer_jump.mouse_key_button = InputActionDef.MouseKeyButton.ENTER
	layer.actions[&"test_jump"] = layer_jump
	action_set.layers[&"menu"] = layer
	return action_set

func _refresh() -> void:
	InputRelay.remapper.refresh_mappings()

func _action_event(action: StringName, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	return event

func _joy_event(device_id: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	return event

func _key_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.device = InputRelay.KEYBOARD_INDEX
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	return event



func test_get_player_returns_matching_number() -> void:
	assert_eq(InputRelay.get_player(2).number, 2)

func test_get_player_zero_is_rejected() -> void:
	assert_null(InputRelay.get_player(0))
	assert_push_error_count(1)

func test_get_player_beyond_max_is_rejected() -> void:
	assert_null(InputRelay.get_player(3))
	assert_push_error_count(1)

func test_get_device_by_index() -> void:
	assert_same(InputRelay.get_device(PAD_ID), pad)
	assert_null(InputRelay.get_device(999))

func test_get_device_owner() -> void:
	assert_eq(InputRelay.get_device_owner(PAD_ID), 1)
	assert_eq(InputRelay.get_device_owner(SECOND_PAD_ID), 2)
	assert_eq(InputRelay.get_device_owner(999), 0)

func test_mouse_device_id_resolves_to_keyboard_owner() -> void:
	assert_eq(InputRelay.get_device_owner(InputEvent.DEVICE_ID_MOUSE), 1)

func test_device_is_assigned() -> void:
	assert_true(InputRelay.device_is_assigned(PAD_ID))
	assert_false(InputRelay.device_is_assigned(999))

func test_player_device_queries() -> void:
	assert_true(InputRelay.player_has_devices(1))
	assert_true(InputRelay.player_has_non_keyboard_devices(1))
	InputRelay.clear_devices(2)
	assert_false(InputRelay.player_has_devices(2))
	assert_false(InputRelay.player_has_non_keyboard_devices(2))

func test_assign_device_moves_between_players() -> void:
	InputRelay.assign_device(PAD_ID, 2)
	assert_eq(InputRelay.get_device_owner(PAD_ID), 2)
	assert_false(player_one.devices.has(pad))
	assert_true(player_two.devices.has(pad))

func test_assign_unknown_device_is_rejected() -> void:
	InputRelay.assign_device(999, 1)
	assert_push_error_count(1)

func test_unassign_device_clears_ownership() -> void:
	InputRelay.unassign_device(PAD_ID, 1)
	assert_null(pad.player)
	assert_false(player_one.devices.has(pad))

func test_unassign_unknown_device_is_rejected() -> void:
	InputRelay.unassign_device(999, 1)
	assert_push_error_count(1)

func test_clear_devices_unassigns_everything() -> void:
	InputRelay.clear_devices(1)
	assert_true(player_one.devices.is_empty())
	assert_null(keyboard.player)
	assert_null(pad.player)

func test_unassigned_devices_lists_only_free_devices() -> void:
	InputRelay._register_device(SPARE_PAD_ID, "Spare Pad")
	var result := InputRelay.unassigned_devices()
	assert_eq(result.size(), 1)
	assert_eq(result[0].index, SPARE_PAD_ID)



func test_register_emits_connected() -> void:
	watch_signals(InputRelay)
	InputRelay._register_device(SPARE_PAD_ID, "Spare Pad")
	assert_signal_emitted_with_parameters(InputRelay, "device_connected", [SPARE_PAD_ID])
	assert_not_null(InputRelay.get_device(SPARE_PAD_ID))

func test_first_pad_auto_assigns_to_player_one() -> void:
	InputRelay.clear_devices(1)
	InputRelay._register_device(SPARE_PAD_ID, "Spare Pad")
	assert_eq(InputRelay.get_device_owner(SPARE_PAD_ID), 1)

func test_second_pad_is_not_auto_assigned() -> void:
	InputRelay._register_device(SPARE_PAD_ID, "Spare Pad")
	assert_eq(InputRelay.get_device_owner(SPARE_PAD_ID), 0)

func test_keyboard_auto_assigns_to_player_one() -> void:
	InputRelay.clear_devices(1)
	InputRelay.devices.erase(keyboard)
	InputRelay._register_device(InputRelay.KEYBOARD_INDEX, "Keyboard & Mouse")
	assert_eq(InputRelay.get_device_owner(InputRelay.KEYBOARD_INDEX), 1)

func test_keyboard_respects_disabled_auto_assign() -> void:
	ProjectSettings.set_setting("InputRelay/player_1_auto_assign_keyboard", false)
	InputRelay.clear_devices(1)
	InputRelay.devices.erase(keyboard)
	InputRelay._register_device(InputRelay.KEYBOARD_INDEX, "Keyboard & Mouse")
	assert_eq(InputRelay.get_device_owner(InputRelay.KEYBOARD_INDEX), 0)

func test_unregister_removes_and_reports_owner() -> void:
	watch_signals(InputRelay)
	InputRelay._unregister_device(PAD_ID)
	assert_signal_emitted_with_parameters(InputRelay, "device_disconnected", [PAD_ID, 1])
	assert_null(InputRelay.get_device(PAD_ID))
	assert_false(player_one.devices.has(pad))

func test_unregister_unowned_reports_zero() -> void:
	InputRelay._register_device(SPARE_PAD_ID, "Spare Pad")
	watch_signals(InputRelay)
	InputRelay._unregister_device(SPARE_PAD_ID)
	assert_signal_emitted_with_parameters(InputRelay, "device_disconnected", [SPARE_PAD_ID, 0])



func test_await_and_assign_claims_next_free_device() -> void:
	InputRelay._register_device(SPARE_PAD_ID, "Spare Pad")
	InputRelay.await_and_assign_device(2)
	assert_eq(InputRelay.player_awaiting_assignment, 2)
	InputRelay._input(_joy_event(SPARE_PAD_ID))
	assert_eq(InputRelay.get_device_owner(SPARE_PAD_ID), 2)
	assert_eq(InputRelay.player_awaiting_assignment, 0)

func test_await_ignores_already_assigned_devices() -> void:
	InputRelay.await_and_assign_device(2)
	InputRelay._input(_joy_event(PAD_ID))
	assert_eq(InputRelay.get_device_owner(PAD_ID), 1)
	assert_eq(InputRelay.player_awaiting_assignment, 2)

func test_await_survives_unregistered_device_input() -> void:
	InputRelay.await_and_assign_device(2)
	InputRelay._input(_joy_event(999))
	assert_eq(InputRelay.player_awaiting_assignment, 2)

func test_stop_awaiting_clears_request() -> void:
	InputRelay.await_and_assign_device(2)
	InputRelay.stop_awaiting_device_assign()
	assert_eq(InputRelay.player_awaiting_assignment, 0)

func test_await_out_of_range_is_rejected() -> void:
	InputRelay.await_and_assign_device(99)
	assert_eq(InputRelay.player_awaiting_assignment, 0)
	assert_push_error_count(1)



func test_joy_input_switches_last_device() -> void:
	watch_signals(InputRelay)
	InputRelay._input(_joy_event(PAD_ID))
	assert_signal_emitted_with_parameters(InputRelay, "switch_current_device_type", [1, InputRelay.KEYBOARD_INDEX, PAD_ID])
	assert_eq(player_one.last_device, PAD_ID)
	assert_eq(InputRelay.last_player_input, 1)

func test_keyboard_input_switches_back() -> void:
	player_one.last_device = PAD_ID
	InputRelay._input(_key_event())
	assert_eq(player_one.last_device, InputRelay.KEYBOARD_INDEX)

func test_mouse_input_counts_as_keyboard() -> void:
	player_one.last_device = PAD_ID
	var event := InputEventMouseButton.new()
	event.device = InputEvent.DEVICE_ID_MOUSE
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	InputRelay._input(event)
	assert_eq(player_one.last_device, InputRelay.KEYBOARD_INDEX)

func test_unassigned_device_input_changes_nothing() -> void:
	watch_signals(InputRelay)
	InputRelay._input(_joy_event(SPARE_PAD_ID))
	assert_eq(InputRelay.last_player_input, 0)
	assert_signal_not_emitted(InputRelay, "switch_current_device_type")
	assert_eq(player_one.last_device, InputRelay.KEYBOARD_INDEX)

func test_mouse_motion_accumulates_scaled_axis() -> void:
	var event := InputEventMouseMotion.new()
	event.screen_relative = Vector2(10.0, -20.0)
	InputRelay._input(event)
	assert_almost_eq(InputRelay._mouse_axis.x, 0.1, 0.0001)
	assert_almost_eq(InputRelay._mouse_axis.y, -0.2, 0.0001)



func test_set_player_action_set_updates_player() -> void:
	settings.action_sets[&"other"] = InputActionSet.new()
	var layers: Array[StringName] = [&"menu"]
	player_two.current_action_layers = layers
	InputRelay.set_player_action_set(2, &"other")
	assert_eq(player_two.current_action_set, &"other")
	assert_true(player_two.current_action_layers.is_empty())

func test_set_player_action_set_rejects_unknown_key() -> void:
	InputRelay.set_player_action_set(2, &"missing")
	assert_eq(player_two.current_action_set, SET_KEY)
	assert_push_error_count(1)

func test_set_player_action_set_rejects_bad_player() -> void:
	InputRelay.set_player_action_set(0, SET_KEY)
	assert_push_error_count(1)

func test_set_player_action_set_builds_input_map() -> void:
	InputRelay.set_player_action_set(2, SET_KEY)
	assert_true(InputMap.has_action(&"test_jump2"))

func test_keyboard_player_applies_keyboard_mouse_mode() -> void:
	settings.action_sets[SET_KEY].mouse_mode_keyboard = Input.MOUSE_MODE_CONFINED
	player_one.last_device = InputRelay.KEYBOARD_INDEX
	InputRelay.set_player_action_set(1, SET_KEY)
	assert_eq(Input.mouse_mode, Input.MOUSE_MODE_CONFINED)

func test_set_layers_applies_valid_layers() -> void:
	var layers: Array[StringName] = [&"menu"]
	InputRelay.set_player_action_layers(2, layers)
	assert_eq(player_two.current_action_layers, layers)

func test_set_layers_rejects_unknown_layer() -> void:
	var layers: Array[StringName] = [&"missing"]
	InputRelay.set_player_action_layers(2, layers)
	assert_true(player_two.current_action_layers.is_empty())
	assert_push_error_count(1)

func test_empty_layers_clear_active_layers() -> void:
	var layers: Array[StringName] = [&"menu"]
	InputRelay.set_player_action_layers(2, layers)
	var empty: Array[StringName] = []
	InputRelay.set_player_action_layers(2, empty)
	assert_true(player_two.current_action_layers.is_empty())

func test_set_and_layers_returns_set_first() -> void:
	var action_set: InputActionSet = settings.action_sets[SET_KEY]
	var result := InputRelay.get_player_action_set_and_layers(2)
	assert_eq(result.size(), 1)
	assert_same(result[0], action_set)

func test_set_and_layers_includes_active_layers() -> void:
	var action_set: InputActionSet = settings.action_sets[SET_KEY]
	var layers: Array[StringName] = [&"menu"]
	player_two.current_action_layers = layers
	var result := InputRelay.get_player_action_set_and_layers(2)
	assert_eq(result.size(), 2)
	assert_same(result[1], action_set.layers[&"menu"])

func test_has_mouse_and_keyboard_assigned() -> void:
	assert_true(InputRelay.has_mouse_and_keyboard_assigned(1))
	assert_false(InputRelay.has_mouse_and_keyboard_assigned(2))



func test_toggle_action_latches_until_second_press() -> void:
	InputRelay.remapper.remap_update_toggle(SET_KEY, &"", &"test_jump", 1, true)
	_refresh()
	InputRelay._input(_action_event(&"test_jump1", true))
	assert_true(Input.is_action_pressed(&"test_jump1"), "First press latches")
	InputRelay._input(_action_event(&"test_jump1", false))
	assert_true(Input.is_action_pressed(&"test_jump1"), "Release is ignored")
	InputRelay._input(_action_event(&"test_jump1", true))
	assert_false(Input.is_action_pressed(&"test_jump1"), "Second press releases")

func test_toggle_rewrites_event_state() -> void:
	InputRelay.remapper.remap_update_toggle(SET_KEY, &"", &"test_jump", 1, true)
	_refresh()
	InputRelay._input(_action_event(&"test_jump1", true))
	var release := _action_event(&"test_jump1", false)
	InputRelay._input(release)
	assert_true(release.pressed)

func test_diagonal_input_is_normalized() -> void:
	_refresh()
	Input.action_press(&"test_move_right1", 1.0)
	Input.action_press(&"test_move_down1", 1.0)
	var event := _action_event(&"test_move_right1", true)
	InputRelay._input(event)
	assert_almost_eq(Input.get_action_strength(&"test_move_right1"), 0.7071, 0.001)
	assert_almost_eq(Input.get_action_strength(&"test_move_down1"), 0.7071, 0.001)
	assert_almost_eq(event.strength, 0.7071, 0.001)

func test_cardinal_input_keeps_full_strength() -> void:
	_refresh()
	Input.action_press(&"test_move_left1", 1.0)
	InputRelay._input(_action_event(&"test_move_left1", true))
	assert_almost_eq(Input.get_action_strength(&"test_move_left1"), 1.0, 0.001)

func test_velocity_uses_definition_sensitivity() -> void:
	_refresh()
	Input.action_press(&"test_look_right1", 0.25)
	InputRelay._input(_action_event(&"test_look_right1", true))
	assert_almost_eq(Input.get_action_strength(&"test_look_right1"), 0.5, 0.001)

func test_velocity_uses_remapped_sensitivity() -> void:
	InputRelay.remapper.remap_update_sensitivity(SET_KEY, &"", &"test_look", 1, 3.0)
	_refresh()
	Input.action_press(&"test_look_right1", 0.25)
	InputRelay._input(_action_event(&"test_look_right1", true))
	assert_almost_eq(Input.get_action_strength(&"test_look_right1"), 0.75, 0.001)

func test_stick_action_parts() -> void:
	assert_eq(InputRelay._get_stick_action_parts("move_left1"), ["move", "1"])
	assert_eq(InputRelay._get_stick_action_parts("move_up"), ["move", ""])
	assert_eq(InputRelay._get_stick_action_parts("look_right12"), ["look", "12"])
	assert_eq(InputRelay._get_stick_action_parts("move2_left"), ["move2", ""])

func test_stick_action_parts_rejects_non_directional() -> void:
	assert_eq(InputRelay._get_stick_action_parts("jump1").size(), 0)
	assert_eq(InputRelay._get_stick_action_parts("jump").size(), 0)

func test_proxy_set_action_strength() -> void:
	_refresh()
	InputRelay._proxy_set_action_strength(&"test_jump1", 0.6)
	assert_almost_eq(Input.get_action_strength(&"test_jump1"), 0.6, 0.001)
	InputRelay._proxy_set_action_strength(&"test_jump1", 0.0)
	assert_false(Input.is_action_pressed(&"test_jump1"))



func test_vibrate_targets_only_requested_player() -> void:
	var first := StubDevice.new(70)
	var second := StubDevice.new(71)
	player_one.devices.append(first)
	player_two.devices.append(second)
	InputRelay.vibrate_player(1, 0.5, 0.25, 0.1)
	assert_eq(first.vibrate_calls, [Vector3(0.5, 0.25, 0.1)])
	assert_eq(second.vibrate_calls.size(), 0)

func test_vibrate_zero_targets_every_player() -> void:
	var first := StubDevice.new(70)
	var second := StubDevice.new(71)
	player_one.devices.append(first)
	player_two.devices.append(second)
	InputRelay.vibrate_player(0, 0.5, 0.25, 0.1)
	assert_eq(first.vibrate_calls.size(), 1)
	assert_eq(second.vibrate_calls.size(), 1)

func test_vibrate_out_of_range_is_rejected() -> void:
	InputRelay.vibrate_player(99, 0.5, 0.5, 0.1)
	assert_push_error_count(1)

func test_vibrate_skips_devices_without_haptics() -> void:
	InputRelay.vibrate_player(1, 0.5, 0.5, 0.1)
	pass_test("No crash")

func test_vibration_helpers_use_preset_values() -> void:
	var stub := StubDevice.new(70)
	player_one.devices.append(stub)
	InputRelay.vibrate_player_tap(1)
	InputRelay.vibrate_player_strong(1)
	assert_eq(stub.vibrate_calls[0], InputRelay._HAPTIC_TAP)
	assert_eq(stub.vibrate_calls[1], InputRelay._HAPTIC_STRONG)

func test_haptic_presets_scale_upward() -> void:
	assert_lt(InputRelay._HAPTIC_TAP.z, InputRelay._HAPTIC_WEAK.z)
	assert_lt(InputRelay._HAPTIC_WEAK.z, InputRelay._HAPTIC_MEDIUM.z)
	assert_lt(InputRelay._HAPTIC_MEDIUM.z, InputRelay._HAPTIC_STRONG.z)

func test_player_is_vibrating() -> void:
	var stub := StubDevice.new(70)
	player_two.devices.append(stub)
	assert_false(InputRelay.player_is_vibrating(2))
	stub.vibrating = true
	assert_true(InputRelay.player_is_vibrating(2))
	assert_true(InputRelay.player_is_vibrating(0))
	assert_false(InputRelay.player_is_vibrating(1))

func test_stop_vibrating_targets_requested_player() -> void:
	var first := StubDevice.new(70)
	var second := StubDevice.new(71)
	player_one.devices.append(first)
	player_two.devices.append(second)
	InputRelay.stop_vibrating_player(1)
	assert_eq(first.stop_calls, 1)
	assert_eq(second.stop_calls, 0)

func test_stop_vibrating_zero_reaches_every_player() -> void:
	var first := StubDevice.new(70)
	var second := StubDevice.new(71)
	player_one.devices.append(first)
	player_two.devices.append(second)
	InputRelay.stop_vibrating_player(0)
	assert_eq(first.stop_calls, 1)
	assert_eq(second.stop_calls, 1)



func test_action_string_follows_last_device() -> void:
	assert_eq(InputRelay.get_player_action_string(1, &"test_jump"), &"Space")
	player_one.last_device = PAD_ID
	assert_eq(InputRelay.get_player_action_string(1, &"test_jump"), &"South Button")

func test_action_string_reflects_remap() -> void:
	InputRelay.remapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.TAB)
	assert_eq(InputRelay.get_player_action_string(1, &"test_jump"), &"Tab")

func test_action_string_reflects_active_layer() -> void:
	var layers: Array[StringName] = [&"menu"]
	player_one.current_action_layers = layers
	assert_eq(InputRelay.get_player_action_string(1, &"test_jump"), &"Enter")

func test_action_string_empty_when_unbound() -> void:
	InputRelay.remapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.NONE)
	assert_eq(InputRelay.get_player_action_string(1, &"test_jump"), &"")

func test_action_string_rejects_bad_player() -> void:
	assert_eq(InputRelay.get_player_action_string(0, &"test_jump"), &"")
	assert_push_error_count(1)

func test_action_glyph_returns_bound_glyph() -> void:
	var texture := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.space_glyph = texture
	assert_same(InputRelay.get_player_action_glyph(1, &"test_jump"), texture)

func test_action_glyph_falls_back_when_missing() -> void:
	var fallback := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.fallback_glyph = fallback
	InputRelay.remapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	assert_same(InputRelay.get_player_action_glyph(1, &"test_jump"), fallback)

func test_action_glyph_rejects_bad_player() -> void:
	assert_null(InputRelay.get_player_action_glyph(0, &"test_jump"))
	assert_push_error_count(1)

func test_device_glyph_and_string() -> void:
	var texture := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.device_glyph = texture
	assert_same(InputRelay.get_player_device_glyph(1), texture)
	assert_eq(InputRelay.get_player_device_string(1), &"Keyboard & Mouse")

func test_directional_string_keyboard_digital() -> void:
	assert_eq(InputRelay.get_player_directional_action_string(1, &"test_move", "up"), &"W")
	assert_eq(InputRelay.get_player_directional_action_string(1, &"test_move", "right"), &"D")

func test_directional_string_joy_stick() -> void:
	player_one.last_device = PAD_ID
	assert_eq(InputRelay.get_player_directional_action_string(1, &"test_move", ""), &"Left Stick")
	assert_eq(InputRelay.get_player_directional_action_string(1, &"test_move", "up"), &"Left Stick Up")

func test_directional_string_unknown_direction_is_unspecified() -> void:
	player_one.last_device = PAD_ID
	assert_eq(InputRelay.get_player_directional_action_string(1, &"test_move", "sideways"), &"Left Stick")

func test_directional_string_mouse_motion() -> void:
	assert_eq(InputRelay.get_player_directional_action_string(1, &"test_look", ""), &"Mouse")
	assert_eq(InputRelay.get_player_directional_action_string(1, &"test_look", "up"), &"Mouse Up")

func test_directional_string_honors_mouse_motion_remap() -> void:
	InputRelay.remapper.remap_update_mouse_motion(SET_KEY, &"", &"test_move", 1, true)
	assert_eq(InputRelay.get_player_directional_action_string(1, &"test_move", ""), &"Mouse")

func test_directional_string_dpad_buttons() -> void:
	player_one.last_device = PAD_ID
	assert_eq(InputRelay.get_player_directional_action_string(1, &"test_pad", "up"), &"D-Pad Up")
	assert_eq(InputRelay.get_player_directional_action_string(1, &"test_pad", "left"), &"D-Pad Left")

func test_directional_glyph_falls_back_to_unspecified_direction() -> void:
	player_one.last_device = PAD_ID
	var texture := PlaceholderTexture2D.new()
	settings.xbox_glyph_map.left_stick_glyph = texture
	assert_same(InputRelay.get_player_directional_action_glyph(1, &"test_move", "up"), texture)

func test_directional_glyph_prefers_specific_direction() -> void:
	player_one.last_device = PAD_ID
	var general := PlaceholderTexture2D.new()
	var specific := PlaceholderTexture2D.new()
	settings.xbox_glyph_map.left_stick_glyph = general
	settings.xbox_glyph_map.left_stick_up_glyph = specific
	assert_same(InputRelay.get_player_directional_action_glyph(1, &"test_move", "up"), specific)



func test_remap_devices_for_player() -> void:
	assert_eq(InputRelay._remap_devices_for_player(1).size(), 2)
	assert_eq(InputRelay._remap_devices_for_player(0).size(), 3)

func test_remap_target_players() -> void:
	assert_eq(InputRelay._remap_target_players(0), [1, 2])
	assert_eq(InputRelay._remap_target_players(2), [2])

func test_remap_await_times_out_without_input() -> void:
	var applied: bool = await InputRelay.remap_button_await(SET_KEY, &"", &"test_jump", 2, 0.05)
	assert_false(applied)
	assert_false(InputRelay.remapper.remap_file.has_section("Player2_Joy"))

func test_remap_await_rejects_bad_player() -> void:
	var applied: bool = await InputRelay.remap_button_await(SET_KEY, &"", &"test_jump", 99, 0.05)
	assert_false(applied)
	assert_push_error_count(1)

func test_directional_remap_await_rejects_bad_player() -> void:
	var applied: bool = await InputRelay.remap_dpad_up_await(SET_KEY, &"", &"test_pad", 99, 0.05)
	assert_false(applied)
	assert_push_error_count(1)

func test_default_escape_buttons() -> void:
	assert_true(InputRelay._DEFAULT_REMAP_ESCAPE_KEYBOARD.has(InputActionDef.MouseKeyButton.ESCAPE))
	assert_true(InputRelay._DEFAULT_REMAP_ESCAPE_JOY.has(InputActionDef.JoypadButton.START))
	assert_true(InputRelay._DEFAULT_REMAP_ESCAPE_JOY.has(InputActionDef.JoypadButton.GUIDE))



func test_find_first_focusable_skips_hidden_and_unfocusable() -> void:
	var root := Control.new()
	var hidden := Button.new()
	hidden.visible = false
	var target := Button.new()
	root.add_child(hidden)
	root.add_child(target)
	add_child_autofree(root)
	assert_same(InputRelay._find_first_focusable(root), target)

func test_find_first_focusable_returns_null_when_none() -> void:
	var root := Control.new()
	add_child_autofree(root)
	assert_null(InputRelay._find_first_focusable(root))



func test_steam_helpers_are_inert_without_singleton() -> void:
	if Engine.has_singleton("Steam"):
		pending("Steam singleton present")
		return
	assert_false(InputRelay._using_steam_input())
	assert_eq(InputRelay._steam_get_action_set_handle(&"anything"), -1)
	InputRelay._steam_activate_player_action_set(1)
	pass_test("No crash")



func test_keyboard_index_matches_engine() -> void:
	assert_eq(InputRelay.KEYBOARD_INDEX, InputEvent.DEVICE_ID_KEYBOARD)

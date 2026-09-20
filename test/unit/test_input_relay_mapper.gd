extends GutTest

const SET_KEY := &"gameplay"
const PAD_ID := 50
const SECOND_PAD_ID := 51
const REMAP_PATH := "user://test_remaps.cfg"

var mapper: InputRelayMapper
var settings: InputRelaySettings
var keyboard: InputRelayDevice
var pad: InputRelayDevice
var player_one: InputRelayPlayer
var player_two: InputRelayPlayer

var saved_settings: InputRelaySettings
var saved_players: Array
var saved_devices: Array
var saved_max_players: int
var saved_auto_save: Variant

func before_each() -> void:
	saved_auto_save = ProjectSettings.get_setting("InputRelay/auto_save_load_remaps", true)
	ProjectSettings.set_setting("InputRelay/auto_save_load_remaps", false)
	saved_settings = InputRelay.settings
	saved_players = InputRelay.players.duplicate()
	saved_devices = InputRelay.devices.duplicate()
	saved_max_players = InputRelay.MAX_PLAYERS
	
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
	var second_pad := InputRelayDevice.new(SECOND_PAD_ID, "Xbox Pad 2", settings)
	player_one = InputRelayPlayer.new(1)
	player_one.devices.assign([keyboard, pad])
	player_one.current_action_set = SET_KEY
	player_one.last_device = InputRelay.KEYBOARD_INDEX
	player_two = InputRelayPlayer.new(2)
	player_two.devices.assign([second_pad])
	player_two.current_action_set = SET_KEY
	player_two.last_device = SECOND_PAD_ID
	
	InputRelay.settings = settings
	InputRelay.MAX_PLAYERS = 2
	InputRelay.players.assign([player_one, player_two])
	InputRelay.devices.assign([keyboard, pad, second_pad])
	
	mapper = InputRelayMapper.new()
	mapper.remap_file = ConfigFile.new()

func after_each() -> void:
	for action_name in mapper._managed_actions:
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)
	InputRelay.settings = saved_settings
	InputRelay.players.assign(saved_players)
	InputRelay.devices.assign(saved_devices)
	InputRelay.MAX_PLAYERS = saved_max_players
	ProjectSettings.set_setting("InputRelay/auto_save_load_remaps", saved_auto_save)
	if FileAccess.file_exists(REMAP_PATH):
		DirAccess.remove_absolute(REMAP_PATH)

func _build_action_set() -> InputActionSet:
	var action_set := InputActionSet.new()
	var jump := InputActionDefDigital.new()
	jump.mouse_key_button = InputActionDef.MouseKeyButton.SPACE
	jump.joy_button = InputActionDef.JoypadButton.SOUTH
	action_set.actions[&"test_jump"] = jump
	var fire := InputActionDefAnalog.new()
	fire.mouse_key_button = InputActionDef.MouseKeyButton.MOUSE_LEFT
	fire.joy_button = InputActionDef.JoypadButton.RIGHT_TRIGGER
	fire.deadzone = 0.25
	action_set.actions[&"test_fire"] = fire
	var move := InputActionDefStickPad.new()
	move.joy_motion = InputActionDef.JoypadMotion.LEFT_STICK
	move.up_mouse_key_button = InputActionDef.MouseKeyButton.W
	move.down_mouse_key_button = InputActionDef.MouseKeyButton.S
	move.left_mouse_key_button = InputActionDef.MouseKeyButton.A
	move.right_mouse_key_button = InputActionDef.MouseKeyButton.D
	move.up_joy_button = InputActionDef.JoypadButton.DPAD_UP
	move.down_joy_button = InputActionDef.JoypadButton.DPAD_DOWN
	move.left_joy_button = InputActionDef.JoypadButton.DPAD_LEFT
	move.right_joy_button = InputActionDef.JoypadButton.DPAD_RIGHT
	action_set.actions[&"test_move"] = move
	var look := InputActionDefStickPadVelocity.new()
	look.joy_motion = InputActionDef.JoypadMotion.RIGHT_STICK
	look.mouse_motion = true
	look.sensitivity = 2.0
	action_set.actions[&"test_look"] = look
	var directional := InputActionDefDirectional.new()
	directional.up_mouse_key_button = InputActionDef.MouseKeyButton.UP
	directional.down_mouse_key_button = InputActionDef.MouseKeyButton.DOWN
	directional.left_mouse_key_button = InputActionDef.MouseKeyButton.LEFT
	directional.right_mouse_key_button = InputActionDef.MouseKeyButton.RIGHT
	directional.up_joy_button = InputActionDef.JoypadButton.DPAD_UP
	action_set.actions[&"test_pad"] = directional
	var layer := InputActionSet.new()
	var layer_jump := InputActionDefDigital.new()
	layer_jump.mouse_key_button = InputActionDef.MouseKeyButton.ENTER
	layer.actions[&"test_jump"] = layer_jump
	action_set.layers[&"menu"] = layer
	return action_set

func _has_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false

func _has_joy_button(action: StringName, button: JoyButton, device_id: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button and event.device == device_id:
			return true
	return false

func _has_joy_axis(action: StringName, axis: int, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and int(event.axis) == axis and is_equal_approx(event.axis_value, value):
			return true
	return false

func _count_events(action: StringName) -> int:
	return InputMap.action_get_events(action).size()



func test_player_one_gets_numbered_and_blank_suffix() -> void:
	assert_eq(mapper._action_suffixes(player_one), ["1", ""])

func test_other_players_get_numbered_suffix_only() -> void:
	assert_eq(mapper._action_suffixes(player_two), ["2"])

func test_remap_key_without_layer() -> void:
	assert_eq(mapper._remap_key(&"set", &"", &"jump"), "set/jump")

func test_remap_key_with_layer() -> void:
	assert_eq(mapper._remap_key(&"set", &"menu", &"jump"), "set/menu/jump")

func test_remap_section_names() -> void:
	assert_eq(mapper._remap_section(0, "Joy"), "Global_Joy")
	assert_eq(mapper._remap_section(2, "Joy"), "Player2_Joy")



func test_digital_creates_numbered_and_blank_actions() -> void:
	mapper.refresh_mappings()
	assert_true(InputMap.has_action(&"test_jump1"))
	assert_true(InputMap.has_action(&"test_jump"))
	assert_true(InputMap.has_action(&"test_jump2"))

func test_digital_binds_keyboard_and_pad_events() -> void:
	mapper.refresh_mappings()
	assert_true(_has_key(&"test_jump1", KEY_SPACE))
	assert_true(_has_joy_button(&"test_jump1", JOY_BUTTON_A, PAD_ID))

func test_second_player_events_use_own_device() -> void:
	mapper.refresh_mappings()
	assert_true(_has_joy_button(&"test_jump2", JOY_BUTTON_A, SECOND_PAD_ID))
	assert_false(_has_joy_button(&"test_jump", JOY_BUTTON_A, SECOND_PAD_ID))

func test_none_binding_adds_no_event() -> void:
	settings.action_sets[SET_KEY].actions[&"test_jump"].mouse_key_button = InputActionDef.MouseKeyButton.NONE
	settings.action_sets[SET_KEY].actions[&"test_jump"].joy_button = InputActionDef.JoypadButton.NONE
	mapper.refresh_mappings()
	assert_eq(_count_events(&"test_jump1"), 0)

func test_mapped_definitions_are_tracked() -> void:
	mapper.refresh_mappings()
	assert_true(mapper.mapped_action_defs[&"test_jump1"] is InputActionDefDigital)
	assert_true(mapper.mapped_action_defs[&"test_move_left1"] is InputActionDefStickPad)

func test_toggle_setting_is_recorded() -> void:
	settings.action_sets[SET_KEY].actions[&"test_jump"].is_toggle = true
	mapper.refresh_mappings()
	assert_true(mapper._action_is_toggle[&"test_jump1"])



func test_analog_applies_deadzone() -> void:
	mapper.refresh_mappings()
	assert_almost_eq(InputMap.action_get_deadzone(&"test_fire1"), 0.25, 0.0001)

func test_analog_trigger_binds_axis() -> void:
	mapper.refresh_mappings()
	assert_true(_has_joy_axis(&"test_fire1", JOY_AXIS_TRIGGER_RIGHT, 1.0))

func test_analog_binds_mouse_button() -> void:
	mapper.refresh_mappings()
	var found := false
	for event in InputMap.action_get_events(&"test_fire1"):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			found = true
	assert_true(found)



func test_stick_pad_creates_four_directions() -> void:
	mapper.refresh_mappings()
	for direction in ["up", "down", "left", "right"]:
		assert_true(InputMap.has_action(StringName("test_move_%s1"%direction)), direction)

func test_stick_pad_binds_stick_axes() -> void:
	mapper.refresh_mappings()
	assert_true(_has_joy_axis(&"test_move_left1", JOY_AXIS_LEFT_X, -1.0))
	assert_true(_has_joy_axis(&"test_move_right1", JOY_AXIS_LEFT_X, 1.0))
	assert_true(_has_joy_axis(&"test_move_up1", JOY_AXIS_LEFT_Y, -1.0))
	assert_true(_has_joy_axis(&"test_move_down1", JOY_AXIS_LEFT_Y, 1.0))

func test_stick_pad_binds_digital_fallbacks() -> void:
	mapper.refresh_mappings()
	assert_true(_has_key(&"test_move_up1", KEY_W))
	assert_true(_has_joy_button(&"test_move_up1", JOY_BUTTON_DPAD_UP, PAD_ID))

func test_stick_pad_events_are_not_duplicated() -> void:
	mapper.refresh_mappings()
	var keys := 0
	for event in InputMap.action_get_events(&"test_move_up1"):
		if event is InputEventKey:
			keys += 1
	assert_eq(keys, 1)

func test_stick_pad_applies_deadzone() -> void:
	mapper.refresh_mappings()
	assert_almost_eq(InputMap.action_get_deadzone(&"test_move_left1"), 0.10, 0.0001)

func test_invert_x_flips_horizontal_sign() -> void:
	mapper.remap_update_invert_x(SET_KEY, &"", &"test_move", 1, true)
	mapper.refresh_mappings()
	assert_true(_has_joy_axis(&"test_move_left1", JOY_AXIS_LEFT_X, 1.0))
	assert_true(_has_joy_axis(&"test_move_right1", JOY_AXIS_LEFT_X, -1.0))

func test_invert_y_flips_vertical_sign() -> void:
	mapper.remap_update_invert_y(SET_KEY, &"", &"test_move", 1, true)
	mapper.refresh_mappings()
	assert_true(_has_joy_axis(&"test_move_up1", JOY_AXIS_LEFT_Y, 1.0))

func test_mouse_motion_adds_proxy_axes() -> void:
	mapper.refresh_mappings()
	assert_true(_has_joy_axis(&"test_look_left1", InputActionDef.PROXY_MOUSE_X, -1.0))
	assert_true(_has_joy_axis(&"test_look_down1", InputActionDef.PROXY_MOUSE_Y, 1.0))

func test_no_mouse_motion_means_no_proxy_axes() -> void:
	mapper.refresh_mappings()
	assert_false(_has_joy_axis(&"test_move_left1", InputActionDef.PROXY_MOUSE_X, -1.0))

func test_velocity_sensitivity_is_recorded() -> void:
	mapper.refresh_mappings()
	assert_almost_eq(mapper._action_sensitivities[&"test_look1"], 2.0, 0.0001)

func test_velocity_sensitivity_override_is_recorded() -> void:
	mapper.remap_update_sensitivity(SET_KEY, &"", &"test_look", 1, 3.5)
	mapper.refresh_mappings()
	assert_almost_eq(mapper._action_sensitivities[&"test_look1"], 3.5, 0.0001)



func test_directional_creates_four_directions() -> void:
	mapper.refresh_mappings()
	for direction in ["up", "down", "left", "right"]:
		assert_true(InputMap.has_action(StringName("test_pad_%s1"%direction)), direction)

func test_directional_binds_buttons_only() -> void:
	mapper.refresh_mappings()
	assert_true(_has_key(&"test_pad_left1", KEY_LEFT))
	assert_true(_has_joy_button(&"test_pad_up1", JOY_BUTTON_DPAD_UP, PAD_ID))
	assert_false(_has_joy_axis(&"test_pad_up1", JOY_AXIS_LEFT_Y, -1.0))



func test_refresh_emits_signal() -> void:
	watch_signals(mapper)
	mapper.refresh_mappings()
	assert_signal_emitted(mapper, "refreshed_mappings")

func test_refresh_erases_stale_actions() -> void:
	mapper.refresh_mappings()
	player_one.current_action_set = &"missing"
	mapper.refresh_mappings()
	assert_false(InputMap.has_action(&"test_jump1"))

func test_refresh_twice_does_not_duplicate_events() -> void:
	mapper.refresh_mappings()
	var first_count := _count_events(&"test_jump1")
	mapper.refresh_mappings()
	assert_eq(_count_events(&"test_jump1"), first_count)

func test_null_action_set_is_skipped() -> void:
	player_one.current_action_set = &"missing"
	mapper.refresh_mappings()
	assert_false(InputMap.has_action(&"test_jump1"))
	assert_true(InputMap.has_action(&"test_jump2"))

func test_active_layer_overrides_action() -> void:
	player_one.current_action_layers.assign([&"menu"])
	mapper.refresh_mappings()
	assert_true(_has_key(&"test_jump1", KEY_ENTER))
	assert_false(_has_key(&"test_jump1", KEY_SPACE))

func test_layer_remap_is_read_from_layer_path() -> void:
	player_one.current_action_layers.assign([&"menu"])
	mapper.remap_key_mouse(SET_KEY, &"menu", &"test_jump", 1, InputActionDef.MouseKeyButton.TAB)
	mapper.refresh_mappings()
	assert_true(_has_key(&"test_jump1", KEY_TAB))

func test_remap_applies_after_refresh() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	mapper.remap_joy_button(SET_KEY, &"", &"test_jump", 1, InputActionDef.JoypadButton.NORTH)
	mapper.refresh_mappings()
	assert_true(_has_key(&"test_jump1", KEY_F))
	assert_true(_has_joy_button(&"test_jump1", JOY_BUTTON_Y, PAD_ID))



func test_key_mouse_defaults_to_definition() -> void:
	assert_eq(mapper.get_remap_key_mouse(SET_KEY, &"", &"test_jump", 1), InputActionDef.MouseKeyButton.SPACE)

func test_key_mouse_remap_round_trip() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	assert_eq(mapper.get_remap_key_mouse(SET_KEY, &"", &"test_jump", 1), InputActionDef.MouseKeyButton.F)

func test_key_mouse_remap_is_per_player() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	assert_eq(mapper.get_remap_key_mouse(SET_KEY, &"", &"test_jump", 2), InputActionDef.MouseKeyButton.SPACE)

func test_key_mouse_clear_restores_default() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	mapper.clear_remap_key_mouse(SET_KEY, &"", &"test_jump", 1)
	assert_eq(mapper.get_remap_key_mouse(SET_KEY, &"", &"test_jump", 1), InputActionDef.MouseKeyButton.SPACE)

func test_joy_button_remap_round_trip() -> void:
	mapper.remap_joy_button(SET_KEY, &"", &"test_jump", 1, InputActionDef.JoypadButton.NORTH)
	assert_eq(mapper.get_remap_joy_button(SET_KEY, &"", &"test_jump", 1), InputActionDef.JoypadButton.NORTH)

func test_joy_button_clear_restores_default() -> void:
	mapper.remap_joy_button(SET_KEY, &"", &"test_jump", 1, InputActionDef.JoypadButton.NORTH)
	mapper.clear_remap_joy_button(SET_KEY, &"", &"test_jump", 1)
	assert_eq(mapper.get_remap_joy_button(SET_KEY, &"", &"test_jump", 1), InputActionDef.JoypadButton.SOUTH)

func test_analog_accepts_button_remaps() -> void:
	mapper.remap_joy_button(SET_KEY, &"", &"test_fire", 1, InputActionDef.JoypadButton.LEFT_TRIGGER)
	assert_eq(mapper.get_remap_joy_button(SET_KEY, &"", &"test_fire", 1), InputActionDef.JoypadButton.LEFT_TRIGGER)

func test_global_remap_uses_separate_section() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 0, InputActionDef.MouseKeyButton.G)
	assert_true(mapper.remap_file.has_section("Global_KeyMouse"))



func test_remap_on_wrong_type_is_rejected() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_move", 1, InputActionDef.MouseKeyButton.F)
	assert_push_error_count(1)
	assert_false(mapper.remap_file.has_section("Player1_KeyMouse"))

func test_unknown_action_is_rejected() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"missing", 1, InputActionDef.MouseKeyButton.F)
	assert_push_error_count(1)

func test_empty_set_is_rejected() -> void:
	mapper.remap_key_mouse(&"", &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	assert_push_error_count(1)

func test_out_of_range_player_is_rejected() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 99, InputActionDef.MouseKeyButton.F)
	assert_push_error_count(1)

func test_invalid_button_value_is_rejected() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, 9999 as InputActionDef.MouseKeyButton)
	assert_push_error_count(1)

func test_getter_on_missing_action_returns_none() -> void:
	assert_eq(mapper.get_remap_key_mouse(SET_KEY, &"", &"missing", 1), InputActionDef.MouseKeyButton.NONE)
	assert_push_error_count(1)



func test_directional_key_mouse_defaults() -> void:
	var keys := mapper.get_remap_directional_key_mouse(SET_KEY, &"", &"test_move", 1)
	assert_eq(keys[0], InputActionDef.MouseKeyButton.W)
	assert_eq(keys[3], InputActionDef.MouseKeyButton.D)

func test_directional_key_mouse_partial_update() -> void:
	mapper.remap_directional_key_mouse(SET_KEY, &"", &"test_move", 1, InputActionDef.MouseKeyButton.I, -1, -1, -1)
	var keys := mapper.get_remap_directional_key_mouse(SET_KEY, &"", &"test_move", 1)
	assert_eq(keys[0], InputActionDef.MouseKeyButton.I)
	assert_eq(keys[1], InputActionDef.MouseKeyButton.S)
	assert_eq(keys[2], InputActionDef.MouseKeyButton.A)
	assert_eq(keys[3], InputActionDef.MouseKeyButton.D)

func test_directional_key_mouse_updates_accumulate() -> void:
	mapper.remap_directional_key_mouse(SET_KEY, &"", &"test_move", 1, InputActionDef.MouseKeyButton.I, -1, -1, -1)
	mapper.remap_directional_key_mouse(SET_KEY, &"", &"test_move", 1, -1, InputActionDef.MouseKeyButton.K, -1, -1)
	var keys := mapper.get_remap_directional_key_mouse(SET_KEY, &"", &"test_move", 1)
	assert_eq(keys[0], InputActionDef.MouseKeyButton.I)
	assert_eq(keys[1], InputActionDef.MouseKeyButton.K)

func test_directional_key_mouse_clear() -> void:
	mapper.remap_directional_key_mouse(SET_KEY, &"", &"test_move", 1, InputActionDef.MouseKeyButton.I, -1, -1, -1)
	mapper.clear_remap_directional_key_mouse(SET_KEY, &"", &"test_move", 1)
	assert_eq(mapper.get_remap_directional_key_mouse(SET_KEY, &"", &"test_move", 1)[0], InputActionDef.MouseKeyButton.W)

func test_directional_joy_button_partial_update() -> void:
	mapper.remap_directional_joy_button(SET_KEY, &"", &"test_pad", 1, -1, InputActionDef.JoypadButton.SOUTH, -1, -1)
	var buttons := mapper.get_remap_directional_joy_button(SET_KEY, &"", &"test_pad", 1)
	assert_eq(buttons[0], InputActionDef.JoypadButton.DPAD_UP)
	assert_eq(buttons[1], InputActionDef.JoypadButton.SOUTH)

func test_directional_remap_rejects_plain_digital() -> void:
	mapper.remap_directional_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.I, -1, -1, -1)
	assert_push_error_count(1)

func test_joy_motion_default_and_remap() -> void:
	assert_eq(mapper.get_remap_directional_joy_motion(SET_KEY, &"", &"test_move", 1), InputActionDef.JoypadMotion.LEFT_STICK)
	mapper.remap_directional_joy_motion(SET_KEY, &"", &"test_move", 1, InputActionDef.JoypadMotion.RIGHT_STICK)
	assert_eq(mapper.get_remap_directional_joy_motion(SET_KEY, &"", &"test_move", 1), InputActionDef.JoypadMotion.RIGHT_STICK)

func test_joy_motion_survives_joy_button_remap() -> void:
	mapper.remap_directional_joy_motion(SET_KEY, &"", &"test_move", 1, InputActionDef.JoypadMotion.RIGHT_STICK)
	mapper.remap_directional_joy_button(SET_KEY, &"", &"test_move", 1, InputActionDef.JoypadButton.SOUTH, -1, -1, -1)
	assert_eq(mapper.get_remap_directional_joy_motion(SET_KEY, &"", &"test_move", 1), InputActionDef.JoypadMotion.RIGHT_STICK)



func test_setting_defaults_come_from_definition() -> void:
	assert_almost_eq(mapper.get_remap_update_deadzone(SET_KEY, &"", &"test_fire", 1), 0.25, 0.0001)
	assert_almost_eq(mapper.get_remap_update_sensitivity(SET_KEY, &"", &"test_look", 1), 2.0, 0.0001)
	assert_true(mapper.get_remap_update_mouse_motion(SET_KEY, &"", &"test_look", 1))
	assert_false(mapper.get_remap_update_invert_x(SET_KEY, &"", &"test_move", 1))
	assert_false(mapper.get_remap_update_toggle(SET_KEY, &"", &"test_jump", 1))

func test_deadzone_round_trip_and_clear() -> void:
	mapper.remap_update_deadzone(SET_KEY, &"", &"test_move", 1, 0.5)
	assert_almost_eq(mapper.get_remap_update_deadzone(SET_KEY, &"", &"test_move", 1), 0.5, 0.0001)
	mapper.clear_remap_update_deadzone(SET_KEY, &"", &"test_move", 1)
	assert_almost_eq(mapper.get_remap_update_deadzone(SET_KEY, &"", &"test_move", 1), 0.10, 0.0001)

func test_deadzone_out_of_range_is_rejected() -> void:
	mapper.remap_update_deadzone(SET_KEY, &"", &"test_move", 1, 1.5)
	assert_push_error_count(1)

func test_deadzone_rejects_digital() -> void:
	mapper.remap_update_deadzone(SET_KEY, &"", &"test_jump", 1, 0.5)
	assert_push_error_count(1)

func test_sensitivity_round_trip() -> void:
	mapper.remap_update_sensitivity(SET_KEY, &"", &"test_look", 1, 4.0)
	assert_almost_eq(mapper.get_remap_update_sensitivity(SET_KEY, &"", &"test_look", 1), 4.0, 0.0001)

func test_sensitivity_rejects_negative() -> void:
	mapper.remap_update_sensitivity(SET_KEY, &"", &"test_look", 1, -1.0)
	assert_push_error_count(1)

func test_sensitivity_rejects_plain_stick_pad() -> void:
	mapper.remap_update_sensitivity(SET_KEY, &"", &"test_move", 1, 2.0)
	assert_push_error_count(1)

func test_toggle_round_trip() -> void:
	mapper.remap_update_toggle(SET_KEY, &"", &"test_jump", 1, true)
	assert_true(mapper.get_remap_update_toggle(SET_KEY, &"", &"test_jump", 1))
	mapper.clear_remap_update_toggle(SET_KEY, &"", &"test_jump", 1)
	assert_false(mapper.get_remap_update_toggle(SET_KEY, &"", &"test_jump", 1))

func test_invert_and_mouse_motion_round_trip() -> void:
	mapper.remap_update_invert_y(SET_KEY, &"", &"test_move", 1, true)
	mapper.remap_update_mouse_motion(SET_KEY, &"", &"test_move", 1, true)
	assert_true(mapper.get_remap_update_invert_y(SET_KEY, &"", &"test_move", 1))
	assert_true(mapper.get_remap_update_mouse_motion(SET_KEY, &"", &"test_move", 1))



func test_clear_remaps_zero_removes_global_only() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 0, InputActionDef.MouseKeyButton.G)
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	mapper.clear_remaps(0)
	assert_false(mapper.remap_file.has_section("Global_KeyMouse"))
	assert_true(mapper.remap_file.has_section("Player1_KeyMouse"))

func test_clear_remaps_player_removes_that_player_only() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 2, InputActionDef.MouseKeyButton.G)
	mapper.clear_remaps(1)
	assert_false(mapper.remap_file.has_section("Player1_KeyMouse"))
	assert_true(mapper.remap_file.has_section("Player2_KeyMouse"))

func test_clear_remaps_one_does_not_touch_player_ten() -> void:
	mapper.remap_file.set_value("Player10_Joy", "set/action", "SOUTH")
	mapper.clear_remaps(1)
	assert_true(mapper.remap_file.has_section("Player10_Joy"))

func test_clear_remaps_out_of_range() -> void:
	mapper.clear_remaps(99)
	assert_push_error_count(1)



func test_save_and_load_round_trip() -> void:
	mapper.remap_file_path = REMAP_PATH
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	mapper.save_remaps()
	var loaded := InputRelayMapper.new()
	loaded.remap_file = ConfigFile.new()
	loaded.remap_file_path = REMAP_PATH
	loaded.load_remaps()
	assert_eq(loaded.get_remap_key_mouse(SET_KEY, &"", &"test_jump", 1), InputActionDef.MouseKeyButton.F)

func test_empty_path_reports_errors() -> void:
	mapper.remap_file_path = ""
	mapper.save_remaps()
	mapper.load_remaps()
	assert_push_error_count(2)

func test_missing_file_loads_without_crash() -> void:
	mapper.remap_file_path = "user://does_not_exist.cfg"
	mapper.load_remaps()
	assert_eq(mapper.get_remap_key_mouse(SET_KEY, &"", &"test_jump", 1), InputActionDef.MouseKeyButton.SPACE)



func test_resolve_button_string_known_names() -> void:
	var keyboard_map := DeviceGlyphMapKeyboard.new()
	assert_eq(mapper._resolve_button_string(keyboard_map, "MOUSE_LEFT"), "Left Click")
	assert_eq(mapper._resolve_button_string(keyboard_map, "SPACE"), "Space")
	assert_eq(mapper._resolve_button_string(DeviceGlyphMapGamepad.new(), "SOUTH"), "South Button")

func test_resolve_button_string_empty_cases() -> void:
	var keyboard_map := DeviceGlyphMapKeyboard.new()
	assert_eq(mapper._resolve_button_string(keyboard_map, "NONE"), "")
	assert_eq(mapper._resolve_button_string(keyboard_map, ""), "")
	assert_eq(mapper._resolve_button_string(keyboard_map, "NOT_A_BUTTON"), "")

func test_input_string_uses_keyboard_binding() -> void:
	assert_eq(mapper._get_input_string(SET_KEY, &"", &"test_jump", 1), "Space")

func test_input_string_uses_joy_binding() -> void:
	player_one.last_device = PAD_ID
	assert_eq(mapper._get_input_string(SET_KEY, &"", &"test_jump", 1), "South Button")

func test_input_string_reflects_remap() -> void:
	mapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.TAB)
	assert_eq(mapper._get_input_string(SET_KEY, &"", &"test_jump", 1), "Tab")

func test_input_string_empty_when_device_missing() -> void:
	player_one.last_device = 777
	assert_eq(mapper._get_input_string(SET_KEY, &"", &"test_jump", 1), "")

func test_directional_string_per_direction() -> void:
	assert_eq(mapper._get_directional_input_string(SET_KEY, &"", &"test_pad", "up", 1), "Up Arrow")
	assert_eq(mapper._get_directional_input_string(SET_KEY, &"", &"test_move", "right", 1), "D")

func test_directional_string_without_direction() -> void:
	assert_eq(mapper._get_directional_input_string(SET_KEY, &"", &"test_move", "", 1), "Mouse")
	player_one.last_device = PAD_ID
	assert_eq(mapper._get_directional_input_string(SET_KEY, &"", &"test_move", "", 1), "Left Stick")



func test_dispatch_without_steam_is_safe() -> void:
	mapper.process_steam_dispatch()
	pass_test("No crash")

func test_clear_steam_state_removes_only_that_handle() -> void:
	mapper.steam_dispatch_entries.append({"steam_input_handle": 7, "target_action": &"test_jump1"})
	mapper.steam_dispatch_entries.append({"steam_input_handle": 8, "target_action": &"test_jump2"})
	mapper._steam_previous_digital["test_jump1"] = true
	mapper._steam_previous_digital["test_jump2"] = true
	mapper.clear_steam_digital_state_for_handle(7)
	assert_false(mapper._steam_previous_digital.has("test_jump1"))
	assert_true(mapper._steam_previous_digital.has("test_jump2"))

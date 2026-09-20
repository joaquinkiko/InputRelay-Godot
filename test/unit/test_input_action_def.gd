extends GutTest

func test_letters_map_to_matching_keys() -> void:
	for offset in 26:
		var button := (InputActionDef.MouseKeyButton.A + offset) as InputActionDef.MouseKeyButton
		assert_eq(InputActionDef.mouse_key_button_to_key(button), (KEY_A + offset) as Key)

func test_digits_map_to_matching_keys() -> void:
	for offset in 10:
		var button := (InputActionDef.MouseKeyButton.KEY_0 + offset) as InputActionDef.MouseKeyButton
		assert_eq(InputActionDef.mouse_key_button_to_key(button), (KEY_0 + offset) as Key)

func test_every_keyboard_button_maps_to_a_key() -> void:
	for button in InputActionDef.MouseKeyButton.values():
		if button == InputActionDef.MouseKeyButton.NONE or InputActionDef.is_mouse_button(button):
			continue
		assert_ne(InputActionDef.mouse_key_button_to_key(button), KEY_NONE, InputActionDef.mouse_key_button_to_string(button))

func test_mouse_buttons_map_to_no_key() -> void:
	assert_eq(InputActionDef.mouse_key_button_to_key(InputActionDef.MouseKeyButton.MOUSE_LEFT), KEY_NONE)

func test_every_mouse_button_maps_to_a_mouse_button() -> void:
	for button in InputActionDef.MouseKeyButton.values():
		if not InputActionDef.is_mouse_button(button):
			continue
		assert_ne(InputActionDef.mouse_key_button_to_mouse_button(button), MOUSE_BUTTON_NONE, InputActionDef.mouse_key_button_to_string(button))

func test_keys_map_to_no_mouse_button() -> void:
	assert_eq(InputActionDef.mouse_key_button_to_mouse_button(InputActionDef.MouseKeyButton.SPACE), MOUSE_BUTTON_NONE)

func test_specific_mouse_mappings() -> void:
	assert_eq(InputActionDef.mouse_key_button_to_mouse_button(InputActionDef.MouseKeyButton.MOUSE_EXTRA1), MOUSE_BUTTON_XBUTTON1)
	assert_eq(InputActionDef.mouse_key_button_to_mouse_button(InputActionDef.MouseKeyButton.MOUSE_WHEEL_UP), MOUSE_BUTTON_WHEEL_UP)

func test_specific_key_mappings() -> void:
	assert_eq(InputActionDef.mouse_key_button_to_key(InputActionDef.MouseKeyButton.ALT), KEY_ALT)
	assert_eq(InputActionDef.mouse_key_button_to_key(InputActionDef.MouseKeyButton.SPACE), KEY_SPACE)



func test_is_mouse_button_boundaries() -> void:
	assert_false(InputActionDef.is_mouse_button(InputActionDef.MouseKeyButton.NONE))
	assert_true(InputActionDef.is_mouse_button(InputActionDef.MouseKeyButton.MOUSE_LEFT))
	assert_true(InputActionDef.is_mouse_button(InputActionDef.MouseKeyButton.MOUSE_EXTRA2))
	assert_false(InputActionDef.is_mouse_button(InputActionDef.MouseKeyButton.A))

func test_is_axis_button() -> void:
	assert_true(InputActionDef.is_axis_button(InputActionDef.JoypadButton.LEFT_TRIGGER))
	assert_true(InputActionDef.is_axis_button(InputActionDef.JoypadButton.RIGHT_TRIGGER))
	assert_false(InputActionDef.is_axis_button(InputActionDef.JoypadButton.SOUTH))



func test_every_joypad_button_resolves_to_button_or_axis() -> void:
	for button in InputActionDef.JoypadButton.values():
		if button == InputActionDef.JoypadButton.NONE:
			continue
		var has_button := InputActionDef.joypad_button_to_joy_button(button) != JOY_BUTTON_INVALID
		var has_axis := InputActionDef.joypad_button_to_joy_axis(button) != JOY_AXIS_INVALID
		assert_true(has_button != has_axis)

func test_face_buttons() -> void:
	assert_eq(InputActionDef.joypad_button_to_joy_button(InputActionDef.JoypadButton.SOUTH), JOY_BUTTON_A)
	assert_eq(InputActionDef.joypad_button_to_joy_button(InputActionDef.JoypadButton.NORTH), JOY_BUTTON_Y)

func test_triggers_map_to_axes() -> void:
	assert_eq(InputActionDef.joypad_button_to_joy_axis(InputActionDef.JoypadButton.LEFT_TRIGGER), JOY_AXIS_TRIGGER_LEFT)
	assert_eq(InputActionDef.joypad_button_to_joy_axis(InputActionDef.JoypadButton.RIGHT_TRIGGER), JOY_AXIS_TRIGGER_RIGHT)

func test_triggers_are_not_joy_buttons() -> void:
	assert_eq(InputActionDef.joypad_button_to_joy_button(InputActionDef.JoypadButton.LEFT_TRIGGER), JOY_BUTTON_INVALID)

func test_none_resolves_to_invalid() -> void:
	assert_eq(InputActionDef.joypad_button_to_joy_button(InputActionDef.JoypadButton.NONE), JOY_BUTTON_INVALID)
	assert_eq(InputActionDef.joypad_button_to_joy_axis(InputActionDef.JoypadButton.NONE), JOY_AXIS_INVALID)



func test_stick_axes() -> void:
	assert_eq(InputActionDef.joypad_motion_to_joy_axes(InputActionDef.JoypadMotion.LEFT_STICK), [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y])
	assert_eq(InputActionDef.joypad_motion_to_joy_axes(InputActionDef.JoypadMotion.RIGHT_STICK), [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y])

func test_none_motion_has_no_axes() -> void:
	assert_eq(InputActionDef.joypad_motion_to_joy_axes(InputActionDef.JoypadMotion.NONE).size(), 0)

func test_gyro_axes() -> void:
	assert_eq(InputActionDef.joypad_motion_to_joy_axes(InputActionDef.JoypadMotion.GYRO), [InputActionDef.PROXY_GYRO_Y, InputActionDef.PROXY_GYRO_Z])



func test_validators_accept_real_values() -> void:
	assert_true(InputActionDef.is_valid_mouse_key_button(InputActionDef.MouseKeyButton.SPACE))
	assert_true(InputActionDef.is_valid_joypad_button(InputActionDef.JoypadButton.TOUCHPAD))
	assert_true(InputActionDef.is_valid_joypad_motion(InputActionDef.JoypadMotion.GYRO))

func test_validators_reject_out_of_range() -> void:
	assert_false(InputActionDef.is_valid_mouse_key_button(9999))
	assert_false(InputActionDef.is_valid_mouse_key_button(-1))
	assert_false(InputActionDef.is_valid_joypad_button(9999))
	assert_false(InputActionDef.is_valid_joypad_motion(9999))



func test_mouse_key_button_round_trip() -> void:
	for button in InputActionDef.MouseKeyButton.values():
		var text := InputActionDef.mouse_key_button_to_string(button)
		assert_eq(InputActionDef.string_to_mouse_key_button(text), button, text)

func test_joypad_button_round_trip() -> void:
	for button in InputActionDef.JoypadButton.values():
		var text := InputActionDef.joypad_button_to_string(button)
		assert_eq(InputActionDef.string_to_joypad_button(text), button, text)

func test_joypad_motion_round_trip() -> void:
	for motion in InputActionDef.JoypadMotion.values():
		var text := InputActionDef.joypad_motion_to_string(motion)
		assert_eq(InputActionDef.string_to_joypad_motion(text), motion, text)

func test_unknown_strings_fall_back_to_none() -> void:
	assert_eq(InputActionDef.string_to_mouse_key_button("BOGUS"), InputActionDef.MouseKeyButton.NONE)
	assert_eq(InputActionDef.string_to_joypad_button(""), InputActionDef.JoypadButton.NONE)
	assert_eq(InputActionDef.string_to_joypad_motion("bogus"), InputActionDef.JoypadMotion.NONE)

func test_invalid_values_serialize_as_none() -> void:
	assert_eq(InputActionDef.mouse_key_button_to_string(9999 as InputActionDef.MouseKeyButton), "NONE")
	assert_eq(InputActionDef.joypad_button_to_string(9999 as InputActionDef.JoypadButton), "NONE")
	assert_eq(InputActionDef.joypad_motion_to_string(9999 as InputActionDef.JoypadMotion), "NONE")



func test_proxy_axes_do_not_collide_with_real_axes() -> void:
	for proxy in [InputActionDef.PROXY_MOUSE_X, InputActionDef.PROXY_MOUSE_Y, InputActionDef.PROXY_GYRO_X, InputActionDef.PROXY_GYRO_Y, InputActionDef.PROXY_GYRO_Z]:
		assert_gt(int(proxy), int(JOY_AXIS_MAX))

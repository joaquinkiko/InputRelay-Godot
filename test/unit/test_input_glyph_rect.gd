extends "res://test/unit/support/relay_fixture.gd"

func _spawn_rect(action: StringName, direction: InputGlyphRect.Direction = InputGlyphRect.Direction.NONE,
		number: int = 1, layer_key: StringName = &"") -> InputGlyphRect:
	var rect := InputGlyphRect.new()
	rect.set_key = SET_KEY
	rect.layer_key = layer_key
	rect.action_name = action
	rect.direction = direction
	rect.player_number = number
	add_child_autofree(rect)
	return rect



func test_keyboard_button_glyph() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.space_glyph = glyph
	assert_same(_spawn_rect(&"test_jump").texture, glyph)

func test_gamepad_button_glyph() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.xbox_glyph_map.south_glyph = glyph
	player_one.last_device = PAD_ID
	assert_same(_spawn_rect(&"test_jump").texture, glyph)

func test_second_player_uses_own_device() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.xbox_glyph_map.south_glyph = glyph
	assert_same(_spawn_rect(&"test_jump", InputGlyphRect.Direction.NONE, 2).texture, glyph)

func test_remap_is_reflected_after_refresh() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.f_glyph = glyph
	var rect := _spawn_rect(&"test_jump")
	InputRelay.remapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	rect.refresh()
	assert_same(rect.texture, glyph)

func test_unbound_action_clears_texture() -> void:
	settings.mouse_keyboard_glyph_map.space_glyph = PlaceholderTexture2D.new()
	var rect := _spawn_rect(&"test_jump")
	assert_not_null(rect.texture)
	InputRelay.remapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.NONE)
	rect.refresh()
	assert_null(rect.texture)

func test_missing_glyph_uses_fallback() -> void:
	var fallback := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.fallback_glyph = fallback
	assert_same(_spawn_rect(&"test_jump").texture, fallback)



func test_layer_action_resolves_with_layer_key() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.enter_glyph = glyph
	assert_same(_spawn_rect(&"test_confirm", InputGlyphRect.Direction.NONE, 1, &"menu").texture, glyph)

func test_layer_action_without_layer_key_is_unresolved() -> void:
	var rect := _spawn_rect(&"test_confirm")
	assert_null(rect.texture)
	assert_push_error_count(1)



func test_stick_pad_gamepad_uses_motion_glyph() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.xbox_glyph_map.left_stick_glyph = glyph
	player_one.last_device = PAD_ID
	assert_same(_spawn_rect(&"test_move").texture, glyph)

func test_stick_pad_keyboard_without_mouse_motion_is_empty() -> void:
	settings.mouse_keyboard_glyph_map.mouse_motion_glyph = PlaceholderTexture2D.new()
	assert_null(_spawn_rect(&"test_move").texture)

func test_stick_pad_keyboard_with_mouse_motion() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.mouse_motion_glyph = glyph
	assert_same(_spawn_rect(&"test_look").texture, glyph)



func test_directional_keyboard_glyph() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.left_glyph = glyph
	assert_same(_spawn_rect(&"test_pad", InputGlyphRect.Direction.LEFT).texture, glyph)

func test_directional_gamepad_glyph() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.xbox_glyph_map.dpad_left_glyph = glyph
	player_one.last_device = PAD_ID
	assert_same(_spawn_rect(&"test_pad", InputGlyphRect.Direction.LEFT).texture, glyph)

func test_stick_pad_direction_uses_binding_glyph() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.w_glyph = glyph
	assert_same(_spawn_rect(&"test_move", InputGlyphRect.Direction.UP).texture, glyph)



func test_out_of_range_player_clears_texture() -> void:
	var rect := _spawn_rect(&"test_jump", InputGlyphRect.Direction.NONE, 3)
	assert_null(rect.texture)
	assert_push_error_count(1)

func test_missing_device_clears_texture() -> void:
	settings.mouse_keyboard_glyph_map.space_glyph = PlaceholderTexture2D.new()
	player_one.last_device = 777
	assert_null(_spawn_rect(&"test_jump").texture)



func test_glyph_follows_device_switch() -> void:
	var keyboard_glyph := PlaceholderTexture2D.new()
	var pad_glyph := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.space_glyph = keyboard_glyph
	settings.xbox_glyph_map.south_glyph = pad_glyph
	var rect := _spawn_rect(&"test_jump")
	assert_same(rect.texture, keyboard_glyph)
	InputRelay.switch_current_device_type.emit(1, InputRelay.KEYBOARD_INDEX, PAD_ID)
	player_one.last_device = PAD_ID
	await get_tree().process_frame
	assert_same(rect.texture, pad_glyph)

func test_other_players_switch_is_ignored() -> void:
	var keyboard_glyph := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.space_glyph = keyboard_glyph
	settings.xbox_glyph_map.south_glyph = PlaceholderTexture2D.new()
	var rect := _spawn_rect(&"test_jump")
	player_one.last_device = PAD_ID
	InputRelay.switch_current_device_type.emit(2, SECOND_PAD_ID, SECOND_PAD_ID)
	await get_tree().process_frame
	assert_same(rect.texture, keyboard_glyph)

func test_rect_refreshes_when_mappings_refresh() -> void:
	var glyph := PlaceholderTexture2D.new()
	settings.mouse_keyboard_glyph_map.f_glyph = glyph
	var rect := _spawn_rect(&"test_jump")
	InputRelay.remapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.F)
	InputRelay.remapper.refresh_mappings()
	await get_tree().process_frame
	assert_same(rect.texture, glyph)

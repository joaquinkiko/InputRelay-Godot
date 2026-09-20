extends "res://test/unit/support/relay_fixture.gd"

class StubRemapper extends ButtonRemapper:
	var stub_applies := true
	
	func _run_remap() -> bool:
		if stub_applies:
			InputRelay.remapper.remap_key_mouse(set_key, layer_key, action_name, player_number, InputActionDef.MouseKeyButton.TAB)
		return stub_applies

var dummy_translation: Translation
var saved_locale: String

func before_each() -> void:
	super()
	saved_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	dummy_translation = Translation.new()
	dummy_translation.locale = "en"
	TranslationServer.add_translation(dummy_translation)
	InputRelay.remapper.refresh_translations()

func after_each() -> void:
	TranslationServer.remove_translation(dummy_translation)
	TranslationServer.set_locale(saved_locale)
	super()

func _spawn(instance: ButtonRemapper, action: StringName = &"test_jump",
		direction: InputGlyphRect.Direction = InputGlyphRect.Direction.NONE, number: int = 1) -> ButtonRemapper:
	instance.set_key = SET_KEY
	instance.action_name = action
	instance.direction = direction
	instance.player_number = number
	add_child_autofree(instance)
	instance.refresh()
	return instance



func test_shows_keyboard_binding() -> void:
	assert_eq(_spawn(ButtonRemapper.new()).text, "Space")

func test_shows_gamepad_binding_for_last_device() -> void:
	player_one.last_device = PAD_ID
	InputRelay.remapper.refresh_translations()
	assert_eq(_spawn(ButtonRemapper.new()).text, "South Button")

func test_second_player_reads_numbered_key() -> void:
	assert_eq(_spawn(ButtonRemapper.new(), &"test_jump", InputGlyphRect.Direction.NONE, 2).text, "South Button")

func test_player_zero_displays_player_one() -> void:
	assert_eq(_spawn(ButtonRemapper.new(), &"test_jump", InputGlyphRect.Direction.NONE, 0).text, "Space")

func test_directional_display() -> void:
	assert_eq(_spawn(ButtonRemapper.new(), &"test_pad", InputGlyphRect.Direction.LEFT).text, "Left Arrow")

func test_unbound_shows_unbound_text() -> void:
	InputRelay.remapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.NONE)
	InputRelay.remapper.refresh_translations()
	assert_eq(_spawn(ButtonRemapper.new()).text, "Unbound")

func test_custom_unbound_text() -> void:
	InputRelay.remapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.NONE)
	InputRelay.remapper.refresh_translations()
	var instance := ButtonRemapper.new()
	instance.unbound_text = "None"
	assert_eq(_spawn(instance).text, "None")

func test_missing_device_shows_unbound() -> void:
	player_one.last_device = 777
	InputRelay.remapper.refresh_translations()
	assert_eq(_spawn(ButtonRemapper.new()).text, "Unbound")

func test_translation_key_shapes() -> void:
	assert_eq(_spawn(ButtonRemapper.new())._translation_key(), "INPUT_TEST_JUMP")
	assert_eq(_spawn(ButtonRemapper.new(), &"test_jump", InputGlyphRect.Direction.NONE, 0)._translation_key(), "INPUT_TEST_JUMP")
	assert_eq(_spawn(ButtonRemapper.new(), &"test_jump", InputGlyphRect.Direction.NONE, 2)._translation_key(), "INPUT_TEST_JUMP2")
	assert_eq(_spawn(ButtonRemapper.new(), &"test_pad", InputGlyphRect.Direction.RIGHT)._translation_key(), "INPUT_TEST_PAD_RIGHT")
	assert_eq(_spawn(ButtonRemapper.new(), &"test_pad", InputGlyphRect.Direction.DOWN, 2)._translation_key(), "INPUT_TEST_PAD_DOWN2")

func test_refresh_is_ignored_while_listening() -> void:
	var button := _spawn(ButtonRemapper.new())
	button._is_remapping = true
	button.text = button.prompt_text
	button.refresh()
	assert_eq(button.text, button.prompt_text)



func test_refreshes_after_device_switch() -> void:
	var button := _spawn(ButtonRemapper.new())
	InputRelay._input(_joy_event(PAD_ID))
	await get_tree().process_frame
	assert_eq(button.text, "South Button")

func test_refreshes_after_mappings_refresh() -> void:
	var button := _spawn(ButtonRemapper.new())
	InputRelay.remapper.remap_key_mouse(SET_KEY, &"", &"test_jump", 1, InputActionDef.MouseKeyButton.TAB)
	InputRelay.remapper.refresh_mappings()
	InputRelay.remapper.refresh_translations()
	await get_tree().process_frame
	assert_eq(button.text, "Tab")



func test_press_prompts_then_times_out() -> void:
	var button := _spawn(ButtonRemapper.new())
	button.timeout_seconds = 0.05
	watch_signals(button)
	button._pressed()
	assert_eq(button.text, button.prompt_text)
	assert_signal_emitted(button, "remap_started")
	await wait_for_signal(button.remap_finished, 1.0)
	assert_signal_emitted_with_parameters(button, "remap_finished", [false])
	assert_eq(button.text, "Space")

func test_second_press_while_listening_is_ignored() -> void:
	var button := _spawn(ButtonRemapper.new())
	button.timeout_seconds = 0.05
	watch_signals(button)
	button._pressed()
	button._pressed()
	assert_signal_emit_count(button, "remap_started", 1)
	await wait_for_signal(button.remap_finished, 1.0)

func test_applied_remap_updates_display() -> void:
	var button := _spawn(StubRemapper.new()) as StubRemapper
	watch_signals(button)
	button._pressed()
	await get_tree().process_frame
	assert_signal_emitted_with_parameters(button, "remap_finished", [true])
	assert_eq(button.text, "Tab")

func test_rejected_remap_keeps_display() -> void:
	var button := _spawn(StubRemapper.new()) as StubRemapper
	button.stub_applies = false
	watch_signals(button)
	button._pressed()
	await get_tree().process_frame
	assert_signal_emitted_with_parameters(button, "remap_finished", [false])
	assert_eq(button.text, "Space")

func test_unknown_action_fails_cleanly() -> void:
	var button := _spawn(ButtonRemapper.new(), &"missing")
	watch_signals(button)
	button._pressed()
	await get_tree().process_frame
	assert_signal_emitted_with_parameters(button, "remap_finished", [false])
	assert_push_error_count(1)

func test_directional_without_direction_fails_cleanly() -> void:
	var button := _spawn(ButtonRemapper.new(), &"test_pad")
	watch_signals(button)
	button._pressed()
	await get_tree().process_frame
	assert_signal_emitted_with_parameters(button, "remap_finished", [false])
	assert_push_error_count(1)

func test_escape_defaults_are_independent_copies() -> void:
	var button := _spawn(ButtonRemapper.new())
	assert_eq(button.escape_key_mouse_buttons, InputRelay._DEFAULT_REMAP_ESCAPE_KEYBOARD)
	assert_eq(button.escape_joy_buttons, InputRelay._DEFAULT_REMAP_ESCAPE_JOY)
	button.escape_key_mouse_buttons.append(InputActionDef.MouseKeyButton.TAB)
	assert_false(InputRelay._DEFAULT_REMAP_ESCAPE_KEYBOARD.has(InputActionDef.MouseKeyButton.TAB))



func test_input_strings_exist_without_project_translations() -> void:
	TranslationServer.remove_translation(dummy_translation)
	InputRelay.remapper.refresh_translations()
	assert_eq(tr("INPUT_TEST_JUMP"), "Space")

func test_active_layer_overrides_display() -> void:
	var override := InputActionDefDigital.new()
	override.mouse_key_button = InputActionDef.MouseKeyButton.TAB
	settings.action_sets[SET_KEY].layers[&"menu"].actions[&"test_jump"] = override
	player_one.current_action_layers.assign([&"menu"])
	InputRelay.remapper.refresh_translations()
	assert_eq(_spawn(ButtonRemapper.new()).text, "Tab")

func test_inactive_layer_does_not_override_display() -> void:
	var override := InputActionDefDigital.new()
	override.mouse_key_button = InputActionDef.MouseKeyButton.TAB
	settings.action_sets[SET_KEY].layers[&"menu"].actions[&"test_jump"] = override
	InputRelay.remapper.refresh_translations()
	assert_eq(_spawn(ButtonRemapper.new()).text, "Space")

func test_action_localization_override_is_used() -> void:
	settings.action_sets[SET_KEY].actions[&"test_jump"].localizations[&"en"] = &"Leap"
	InputRelay.remapper.refresh_translations()
	assert_eq(tr("ACTION_TEST_JUMP"), "Leap")

func test_set_localization_does_not_break_input_strings() -> void:
	settings.action_sets[SET_KEY].localizations[&"en"] = &"Gameplay"
	InputRelay.remapper.refresh_translations()
	assert_eq(tr("INPUT_TEST_JUMP"), "Space")

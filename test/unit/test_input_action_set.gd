extends GutTest

var original_mouse_mode: Input.MouseMode

func before_each() -> void:
	original_mouse_mode = Input.mouse_mode

func after_each() -> void:
	Input.mouse_mode = original_mouse_mode



func test_collections_are_not_shared() -> void:
	var first := InputActionSet.new()
	var second := InputActionSet.new()
	first.actions[&"jump"] = InputActionDefDigital.new()
	first.layers[&"menu"] = InputActionSet.new()
	first.localizations[&"en"] = &"Gameplay"
	assert_true(second.actions.is_empty())
	assert_true(second.layers.is_empty())
	assert_true(second.localizations.is_empty())



func test_joy_applies_joy_mouse_mode() -> void:
	var action_set := InputActionSet.new()
	action_set.mouse_mode_keyboard = Input.MOUSE_MODE_VISIBLE
	action_set.mouse_mode_joy = Input.MOUSE_MODE_HIDDEN
	action_set.apply_mouse_mode(true)
	assert_eq(Input.mouse_mode, Input.MOUSE_MODE_HIDDEN)

func test_keyboard_applies_keyboard_mouse_mode() -> void:
	var action_set := InputActionSet.new()
	action_set.mouse_mode_keyboard = Input.MOUSE_MODE_CONFINED
	action_set.mouse_mode_joy = Input.MOUSE_MODE_HIDDEN
	action_set.apply_mouse_mode(false)
	assert_eq(Input.mouse_mode, Input.MOUSE_MODE_CONFINED)



func test_uppercase_action_names_are_lowercased() -> void:
	var action_set := InputActionSet.new()
	var definition := InputActionDefDigital.new()
	action_set.actions[&"Jump"] = definition
	action_set.sanitize_keys()
	assert_true(action_set.actions.has(&"jump"))
	assert_false(action_set.actions.has(&"Jump"))
	assert_same(action_set.actions[&"jump"], definition)
	assert_push_error_count(1)

func test_plus_characters_become_spaces() -> void:
	var action_set := InputActionSet.new()
	action_set.actions[&"fire+weapon"] = InputActionDefDigital.new()
	action_set.sanitize_keys()
	assert_true(action_set.actions.has(&"fire weapon"))
	assert_false(action_set.actions.has(&"fire+weapon"))
	assert_push_error_count(1)

func test_layer_names_are_sanitized() -> void:
	var action_set := InputActionSet.new()
	var layer := InputActionSet.new()
	action_set.layers[&"Menu+Overlay"] = layer
	action_set.sanitize_keys()
	assert_true(action_set.layers.has(&"menu overlay"))
	assert_same(action_set.layers[&"menu overlay"], layer)
	assert_push_error_count(1)

func test_layer_actions_are_sanitized_recursively() -> void:
	var action_set := InputActionSet.new()
	var layer := InputActionSet.new()
	layer.actions[&"Confirm"] = InputActionDefDigital.new()
	action_set.layers[&"menu"] = layer
	action_set.sanitize_keys()
	assert_true(layer.actions.has(&"confirm"))
	assert_push_error_count(1)

func test_clean_keys_are_untouched() -> void:
	var action_set := InputActionSet.new()
	action_set.actions[&"jump"] = InputActionDefDigital.new()
	action_set.layers[&"menu"] = InputActionSet.new()
	action_set.sanitize_keys()
	assert_eq(action_set.actions.keys(), [&"jump"])
	assert_eq(action_set.layers.keys(), [&"menu"])
	assert_push_error_count(0)



func test_duplicate_preserves_values() -> void:
	var original := InputActionSet.new()
	original.mouse_mode_joy = Input.MOUSE_MODE_HIDDEN
	original.actions[&"jump"] = InputActionDefDigital.new()
	original.localizations[&"fr"] = &"Jeu"
	var copy := original.duplicate() as InputActionSet
	assert_eq(copy.mouse_mode_joy, Input.MOUSE_MODE_HIDDEN)
	assert_true(copy.actions.has(&"jump"))
	assert_eq(copy.localizations[&"fr"], &"Jeu")



func test_default_ui_set_loads_with_expected_actions() -> void:
	var action_set := load("res://addons/input_relay/default/ui_set.tres") as InputActionSet
	assert_not_null(action_set)
	for action_name in [&"ui", &"ui_accept", &"ui_cancel", &"ui_select", &"ui_page_up", &"ui_page_down"]:
		assert_true(action_set.actions.has(action_name), String(action_name))

func test_default_ui_set_types() -> void:
	var action_set := load("res://addons/input_relay/default/ui_set.tres") as InputActionSet
	assert_true(action_set.actions[&"ui"] is InputActionDefStickPad)
	assert_true(action_set.actions[&"ui_accept"] is InputActionDefDigital)

func test_default_ui_set_keys_are_already_clean() -> void:
	var action_set := load("res://addons/input_relay/default/ui_set.tres") as InputActionSet
	for key in action_set.actions.keys():
		assert_eq(String(key), String(key).to_lower().replace("+", " "))

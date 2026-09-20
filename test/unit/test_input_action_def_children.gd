extends GutTest

func test_directional_extends_base() -> void:
	assert_true(InputActionDefDirectional.new() is InputActionDef)

func test_stick_pad_inherits_directional_bindings() -> void:
	var definition := InputActionDefStickPad.new()
	assert_true(definition is InputActionDefDirectional)
	definition.up_joy_button = InputActionDef.JoypadButton.DPAD_UP
	assert_eq(definition.up_joy_button, InputActionDef.JoypadButton.DPAD_UP)

func test_velocity_inheritance_chain() -> void:
	var definition := InputActionDefStickPadVelocity.new()
	assert_true(definition is InputActionDefStickPad)
	assert_true(definition is InputActionDefDirectional)
	assert_true(definition is InputActionDef)

func test_stick_pad_is_not_velocity() -> void:
	assert_false(InputActionDefStickPad.new() is InputActionDefStickPadVelocity)

func test_directional_is_not_stick_pad() -> void:
	assert_false(InputActionDefDirectional.new() is InputActionDefStickPad)



func test_localizations_default_empty_and_not_shared() -> void:
	var first := InputActionDefDigital.new()
	var second := InputActionDefDigital.new()
	assert_true(first.localizations.is_empty())
	first.localizations[&"en"] = &"Jump"
	assert_true(second.localizations.is_empty())

func test_duplicate_preserves_values() -> void:
	var original := InputActionDefStickPadVelocity.new()
	original.sensitivity = 2.5
	original.invert_y = true
	original.joy_motion = InputActionDef.JoypadMotion.RIGHT_STICK
	var copy := original.duplicate() as InputActionDefStickPadVelocity
	assert_almost_eq(copy.sensitivity, 2.5, 0.0001)
	assert_true(copy.invert_y)
	assert_eq(copy.joy_motion, InputActionDef.JoypadMotion.RIGHT_STICK)

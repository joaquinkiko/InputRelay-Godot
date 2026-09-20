extends GutTest

const FAKE_ID := 99

var settings: InputRelaySettings

func before_each() -> void:
	settings = InputRelaySettings.new()
	settings.mouse_keyboard_glyph_map = DeviceGlyphMapKeyboard.new()
	settings.generic_glyph_map = DeviceGlyphMapGamepad.new()
	settings.xbox_glyph_map = DeviceGlyphMapGamepad.new()
	settings.dualshock_glyph_map = DeviceGlyphMapGamepad.new()
	settings.nintendo_pro_glyph_map = DeviceGlyphMapGamepad.new()



func test_stores_identity() -> void:
	var device := InputRelayDevice.new(FAKE_ID, "Test Pad", settings)
	assert_eq(device.index, FAKE_ID)
	assert_eq(device.name, "Test Pad")
	assert_null(device.player)

func test_steam_handle_defaults_to_unmanaged() -> void:
	var device := InputRelayDevice.new(FAKE_ID, "Pad", settings)
	assert_eq(device.steam_input_handle, 0)
	assert_false(device.is_steam_managed())

func test_null_settings_does_not_crash() -> void:
	var device := InputRelayDevice.new(FAKE_ID, "Pad")
	assert_not_null(device)



func test_xbox_name_selects_xbox_map() -> void:
	assert_same(InputRelayDevice.new(FAKE_ID, "Xbox Controller", settings).glyph_map, settings.xbox_glyph_map)

func test_xinput_name_selects_xbox_map() -> void:
	assert_same(InputRelayDevice.new(FAKE_ID, "XInput Pad", settings).glyph_map, settings.xbox_glyph_map)

func test_playstation_names_select_dualshock_map() -> void:
	for device_name in ["PlayStation 4", "DualShock 4", "DualSense Wireless"]:
		assert_same(InputRelayDevice.new(FAKE_ID, device_name, settings).glyph_map, settings.dualshock_glyph_map, device_name)

func test_nintendo_names_select_nintendo_map() -> void:
	for device_name in ["Nintendo Switch Pro", "Switch Controller"]:
		assert_same(InputRelayDevice.new(FAKE_ID, device_name, settings).glyph_map, settings.nintendo_pro_glyph_map, device_name)

func test_unknown_name_selects_generic_map() -> void:
	assert_same(InputRelayDevice.new(FAKE_ID, "Mystery Pad", settings).glyph_map, settings.generic_glyph_map)

func test_keyboard_index_selects_keyboard_map() -> void:
	var device := InputRelayDevice.new(InputRelay.KEYBOARD_INDEX, "Keyboard & Mouse", settings)
	assert_same(device.glyph_map, settings.mouse_keyboard_glyph_map)

func test_keyboard_index_wins_over_name_matching() -> void:
	var device := InputRelayDevice.new(InputRelay.KEYBOARD_INDEX, "Switch Keyboard", settings)
	assert_same(device.glyph_map, settings.mouse_keyboard_glyph_map)



func test_disconnected_device_has_no_features() -> void:
	var device := InputRelayDevice.new(FAKE_ID, "Pad", settings)
	assert_eq(device.feature_flags, 0)
	assert_false(device.supports_lights())
	assert_false(device.supports_motion())
	assert_false(device.supports_haptic())

func test_supports_helpers_read_flags() -> void:
	var device := InputRelayDevice.new(FAKE_ID, "Pad", settings)
	device.feature_flags = InputRelayDevice.Features.LIGHTS | InputRelayDevice.Features.HAPTIC
	assert_true(device.supports_lights())
	assert_true(device.supports_haptic())
	assert_false(device.supports_motion())



func test_unsupported_calls_do_not_crash() -> void:
	var device := InputRelayDevice.new(FAKE_ID, "Pad", settings)
	device.set_light(Color.RED)
	device.vibrate(0.5, 0.5, 0.1)
	device.get_gyro()
	pass_test("No crash")

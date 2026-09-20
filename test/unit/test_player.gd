extends GutTest

func test_number_is_stored() -> void:
	assert_eq(InputRelayPlayer.new(3).number, 3)


func test_color_setter_stores_value() -> void:
	var player := InputRelayPlayer.new(1)
	player.color = Color.RED
	assert_eq(player.color, Color.RED)

func test_color_setter_no_error_for_devices_without_lights() -> void:
	var player := InputRelayPlayer.new(1)
	player.devices.append(InputRelayDevice.new(99, "Generic Pad", InputRelaySettings.new()))
	player.color = Color.BLUE
	assert_eq(player.color, Color.BLUE)


func test_collections_are_not_shared_between_players() -> void:
	var first := InputRelayPlayer.new(1)
	var second := InputRelayPlayer.new(2)
	first.current_action_layers.append(&"layer")
	assert_true(second.current_action_layers.is_empty())
	first.devices.append(InputRelayDevice.new(99, "Pad", InputRelaySettings.new()))
	assert_true(second.devices.is_empty())


func test_last_device_defaults_to_invalid() -> void:
	assert_eq(InputRelayPlayer.new(1).last_device, -1)

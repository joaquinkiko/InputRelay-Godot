@tool
extends EditorPlugin


const settings := [
	{
		"name": "InputRelay/settings_resource",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "InputRelaySettings",
		"default": null,
	},
	{
		"name": "InputRelay/max_players",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,8,prefer_slider",
		"default": 4,
	},
	{
		"name": "InputRelay/auto_enable_player_1",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"default": true,
	},
	{
		"name": "InputRelay/auto_assign_devices_to_player_1",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"default": true,
	},
	{
		"name": "InputRelay/auto_save_load_remaps",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"default": true,
	},
	{
		"name": "InputRelay/remap_save_load_path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"default": "user://input_remaps.cfg",
	},
]

func _enable_plugin() -> void:
	add_autoload_singleton("InputRelay", "input_relay.gd")
	for setting in settings:
		if not ProjectSettings.has_setting(setting["name"]):
			ProjectSettings.set_setting(setting["name"], setting["default"])
		ProjectSettings.set_initial_value(setting["name"], setting["default"])
		ProjectSettings.add_property_info(setting)

func _disable_plugin() -> void:
	remove_autoload_singleton("InputRelay")
	for setting in settings:
		ProjectSettings.set_setting(setting["name"], null)

@tool
## Configures default settings for InputRelay
class_name InputRelaySettings extends Resource

@export_group("Sets")
## Default [InputActionSet] to use from [member action_sets]
@export var default_action_set: StringName
## All [InputActionSet]s sets, sorted by name
@export var action_sets: Dictionary[StringName, InputActionSet]

@export_group("Glyph Maps")
## [DeviceGlyphMap] to use for mouse and keyboard
@export var mouse_keyboard_glyph_map: DeviceGlyphMapKeyboard
## [DeviceGlyphMap] to use for generic gamepads
@export var generic_glyph_map: DeviceGlyphMapGamepad
## [DeviceGlyphMap] to use for xbox/xinput gamepads
@export var xbox_glyph_map: DeviceGlyphMapGamepad
## [DeviceGlyphMap] to use for dualshock gamepads
@export var dualshock_glyph_map: DeviceGlyphMapGamepad
## [DeviceGlyphMap] to use for nintendo pro gamepads
@export var nintendo_pro_glyph_map: DeviceGlyphMapGamepad

@export_group("Steam Input")
@export_tool_button("Export Steam Input VDF") var export_vdf_button: Callable = _prompt_export_vdf

func _prompt_export_vdf() -> void:
	if not Engine.is_editor_hint():
		return
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialog.add_filter("*.vdf", "Steam Input Manifest")
	dialog.current_file = "in_game_actions.vdf"
	dialog.file_selected.connect(_write_vdf_file)
	dialog.file_selected.connect(func(_path): dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered_ratio()

func _write_vdf_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open %s for writing" % path)
		return
	file.store_string(build_vdf_string())
	file.close()

## Builds the full VDF-ready dictionary from action_sets and their layers
func build_vdf_dictionary() -> Dictionary:
	var actions: Dictionary = {}
	var sets: Dictionary = {}
	var layers: Dictionary = {}
	var default_language := TranslationServer.get_language_name(TranslationServer.get_locale()).to_lower()
	var localization: Dictionary = {default_language: {}}
	for set_key in action_sets:
		var action_set: InputActionSet = action_sets[set_key]
		if action_set == null:
			continue
		var set_name := String(set_key)
		var set_token := "SET_%s" % set_name.to_upper()
		actions[set_name] = _build_action_group(action_set, localization, default_language)
		actions[set_name]["title"] = "#%s" % set_token
		sets[set_name] = {"title": "#%s" % set_token}
		_add_localization_entries(localization, set_token, set_name.capitalize(), action_set.localizations, default_language)
		for layer_key in action_set.layers:
			var layer: InputActionSet = action_set.layers[layer_key]
			if layer == null:
				continue
			var layer_name := String(layer_key)
			var layer_token := "LAYER_%s" % layer_name.to_upper()
			actions[layer_name] = _build_action_group(layer, localization, default_language)
			actions[layer_name]["title"] = "#%s" % layer_token
			layers[layer_name] = {
				"title": "#%s" % layer_token,
				"set_layer": "1",
				"parent_set_name": set_name,
			}
			_add_localization_entries(localization, layer_token, layer_name.capitalize(), layer.localizations, default_language)
	return {"In Game Actions": {"actions": actions, "action_sets": sets, "action_layers": layers, "localization": localization}}

## Writes a token's default-language entry plus any per-locale overrides
func _add_localization_entries(localization: Dictionary, token: String, default_value: String, localizations: Dictionary, default_language: String) -> void:
	localization[default_language][token] = default_value
	for locale in localizations:
		var language_name := TranslationServer.get_language_name(String(locale)).to_lower()
		if not localization.has(language_name):
			localization[language_name] = {}
		localization[language_name][token] = String(localizations[locale])

## Sorts one set/layer's actions into Steam's Button / AnalogTrigger / StickPadGyro groups
func _build_action_group(action_set: InputActionSet, localization: Dictionary, default_language: String) -> Dictionary:
	var groups: Dictionary = {"Button": {}, "AnalogTrigger": {}, "StickPadGyro": {}}
	for action_key in action_set.actions:
		var action_def: InputActionDef = action_set.actions[action_key]
		if action_def == null:
			continue
		var action_name := String(action_key)
		var action_token := "ACTION_%s" % action_name.to_upper()
		var classified := _classify_action(action_token, action_def)
		groups[classified["group"]][action_name] = classified["entry"]
		var default_value := action_name.capitalize().replace(" ", "+")
		_add_localization_entries(localization, action_token, default_value, action_def.localizations, default_language)
	var result: Dictionary = {}
	for group_name in groups:
		if not groups[group_name].is_empty():
			result[group_name] = groups[group_name]
	return result

## Maps an InputActionDef to its Steam Input group + entry
func _classify_action(action_token: String, action_def: InputActionDef) -> Dictionary:
	if action_def is InputActionDefStickPadVelocity:
		return {"group": "StickPadGyro", "entry": {"title": "#%s" % action_token, "input_mode": "joystick_camera"}}
	if action_def is InputActionDefStickPad:
		return {"group": "StickPadGyro", "entry": {"title": "#%s" % action_token, "input_mode": "joystick_move"}}
	if action_def is InputActionDefDirectional:
		return {"group": "StickPadGyro", "entry": {"title": "#%s" % action_token, "input_mode": "dpad"}}
	if action_def is InputActionDefAnalog:
		return {"group": "AnalogTrigger", "entry": {"title": "#%s" % action_token}}
	# Default to Digital
	return {"group": "Button", "entry": {"title": "#%s" % action_token}}

func build_vdf_string() -> String:
	return _serialize_vdf(build_vdf_dictionary(), 0)

## Recursively writes a Dictionary out as KeyValues/VDF text
func _serialize_vdf(data: Dictionary, indent: int) -> String:
	var tabs := "\t".repeat(indent)
	var output := ""
	for key in data:
		var value = data[key]
		if value is Dictionary:
			output += "%s\"%s\"\n%s{\n%s%s}\n" % [tabs, key, tabs, _serialize_vdf(value, indent + 1), tabs]
		else:
			output += "%s\"%s\" \"%s\"\n" % [tabs, key, str(value)]
	return output

## Converts a Steam "SET_*" token back to its original action_sets dictionary key
static func decode_set_token(token: String) -> StringName:
	return StringName(token.trim_prefix("SET_").to_lower())

## Converts a Steam "LAYER_*" token back to its original layers dictionary key
static func decode_layer_token(token: String) -> StringName:
	return StringName(token.trim_prefix("LAYER_").to_lower())

## Converts a Steam "ACTION_*" token back to its original actions dictionary key
static func decode_action_token(token: String) -> StringName:
	return StringName(token.trim_prefix("ACTION_").to_lower())

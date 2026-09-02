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

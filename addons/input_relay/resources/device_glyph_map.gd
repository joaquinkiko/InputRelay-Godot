## Configures glyphs and display information for different device types
@abstract
class_name DeviceGlyphMap extends Resource

## Device glyph
@export var device_glyph: Texture2D
## Human-readable device name
@export var device_string: StringName
## Used when no valid glyph can be found
@export var fallback_glyph: Texture2D

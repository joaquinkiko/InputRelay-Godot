## Stores info on connected device
class_name InputRelayDevice extends RefCounted

enum Features {
	LIGHTS,
	GYRO,
}

## Internal index of device
var index: int
## Human-friendly name
var name: String
## Flags indicating available features
var feature_flags: int
## [DeviceGlyphMap] to use
var glyph_map: DeviceGlyphMap

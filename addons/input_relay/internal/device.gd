## Stores info on connected device
class_name InputRelayDevice extends RefCounted

enum Features {
	LIGHTS = 1 << 0,
	MOTION = 1 << 1,
	HAPTIC = 1 << 2,
}

## Internal index of device
var index: int
## Human-friendly name
var name: String
## Flags indicating available features
var feature_flags: int
## [DeviceGlyphMap] to use
var glyph_map: DeviceGlyphMap
## Player assigned to
var player: InputRelayPlayer

func _init(device_id: int, device_name: String) -> void:
	self.index = device_id
	self.name = device_name
	# Assign feature flags
	if Input.get_connected_joypads().has(device_id):
		if Input.has_joy_light(device_id):
			feature_flags |= Features.LIGHTS
		if Input.has_joy_motion_sensors(device_id):
			feature_flags |= Features.MOTION
		if Input.has_joy_vibration(device_id):
			feature_flags |= Features.HAPTIC
	# Detect type
	# TODO: Finish glyph_map assignment | Improve detection
	var lname := device_name.to_lower()
	if "xbox" in lname || "xinput" in lname:
		pass
	elif "playstation" in lname || "dualshock" in lname || "dualsense" in lname:
		pass
	elif "nintendo" in lname || "switch" in lname:
		pass
	elif "keyboard" in lname:
		pass
	else:
		pass

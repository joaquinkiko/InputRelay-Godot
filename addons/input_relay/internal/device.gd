## Stores info on connected device
class_name InputRelayDevice extends RefCounted

enum Features {
	LIGHTS = 1 << 0,
	MOTION = 1 << 1,
	HAPTIC = 1 << 2,
}

## SDL2 Vendor IDs
enum Vendors {
	MISC = 0,
	MICROSOFT = 0x045E,
	SONY = 0x054C,
	NINTENDO = 0x057E,
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

func _init(device_id: int, device_name: String, settings: InputRelaySettings = null) -> void:
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
	# Get glyph map
	if settings == null:
		settings = InputRelaySettings.new()
	var vendor_id: int = Vendors.MISC
	var product_id: int = 0 # Currently unused
	if Input.get_connected_joypads().has(device_id):
		var info := Input.get_joy_info(device_id)
		vendor_id = info["vendor_id"]
		product_id = info["product_id"]
	# Vendor takes priority on determining Glyph, otherwise fallback to name
	var lname := device_name.to_lower()
	if vendor_id == Vendors.MICROSOFT || "xbox" in lname || "xinput" in lname:
		glyph_map = settings.xbox_glyph_map
	elif vendor_id == Vendors.SONY || "playstation" in lname || "dualshock" in lname || "dualsense" in lname:
		glyph_map = settings.dualshock_glyph_map
	elif vendor_id == Vendors.NINTENDO || "nintendo" in lname || "switch" in lname:
		glyph_map = settings.nintendo_pro_glyph_map
	elif "keyboard" in lname:
		glyph_map = settings.mouse_keyboard_glyph_map
	else:
		glyph_map = settings.generic_glyph_map

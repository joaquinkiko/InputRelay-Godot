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
## Steam Input handle for this device, 0 if not Steam-managed
var steam_input_handle: int

func _init(device_id: int, device_name: String, settings: InputRelaySettings = null, steam_handle: int = 0) -> void:
	self.index = device_id
	self.name = device_name
	self.steam_input_handle = steam_handle
	#  If using Steam Input, allow it to take over rest of setup
	if is_steam_managed():
		var steam := Engine.get_singleton("Steam")
		var input_type: int = steam.getInputTypeForHandle(steam_input_handle)
		feature_flags |= Features.HAPTIC
		match input_type:
			steam.INPUT_TYPE_PS4, steam.INPUT_TYPE_PS5:
				feature_flags |= Features.LIGHTS | Features.MOTION
				glyph_map = settings.dualshock_glyph_map
			steam.INPUT_TYPE_SWITCH_PRO_CONTROLLER:
				feature_flags |= Features.MOTION
				glyph_map = settings.nintendo_pro_glyph_map
			steam.INPUT_TYPE_XBOX360, steam.INPUT_TYPE_XBOXONE:
				glyph_map = settings.xbox_glyph_map
			_:
				glyph_map = settings.generic_glyph_map
		return
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
	elif device_id == InputRelay.KEYBOARD_INDEX:
		glyph_map = settings.mouse_keyboard_glyph_map
	else:
		glyph_map = settings.generic_glyph_map

## Returns true if device supports custom light colors
func supports_lights() -> bool:
	return feature_flags & Features.LIGHTS

## Returns true if device supports gyro detection
func supports_motion() -> bool:
	return feature_flags & Features.MOTION

## Returns true if device supports vibrations
func supports_haptic() -> bool:
	return feature_flags & Features.HAPTIC

## True if this device is currently managed by Steam Input
func is_steam_managed() -> bool:
	return steam_input_handle != 0

## Sets device light color, routing through Steam or native API
func set_light(color: Color) -> void:
	if not supports_lights():
		return
	if is_steam_managed():
		Engine.get_singleton("Steam").setLEDColor(steam_input_handle, roundi(color.r*255), roundi(color.g*255), roundi(color.b*255), 0)
	else:
		Input.set_joy_light(index, color)

## Starts vibration, routing through Steam or native API
func vibrate(weak_motor: float, strong_motor: float, duration: float) -> void:
	if not supports_haptic():
		return
	if is_steam_managed():
		var steam := Engine.get_singleton("Steam")
		steam.triggerVibration(steam_input_handle, int(weak_motor * 65535), int(strong_motor * 65535))
		if duration > 0.0:
			(Engine.get_main_loop() as SceneTree).create_timer(duration).timeout.connect(
				func(): steam.triggerVibration(steam_input_handle, 0, 0))
	else:
		Input.start_joy_vibration(index, weak_motor, strong_motor, duration)

## Stops vibration, routing through Steam or native API
func stop_vibrating() -> void:
	if is_steam_managed():
		Engine.get_singleton("Steam").triggerVibration(steam_input_handle, 0, 0)
	else:
		Input.stop_joy_vibration(index)

## True if device is currently vibrating. Steam doesn't expose this, so always false there.
func is_vibrating() -> bool:
	if is_steam_managed():
		return false
	return Input.is_joy_vibrating(index)

## Returns current gyro rotation velocity, routing through Steam or native API
func get_gyro() -> Vector3:
	if is_steam_managed():
		var motion: Dictionary = Engine.get_singleton("Steam").getMotionData(steam_input_handle)
		return Vector3(motion.get("rotVelX", 0.0), motion.get("rotVelY", 0.0), motion.get("rotVelZ", 0.0))
	return Input.get_joy_gyroscope(index)

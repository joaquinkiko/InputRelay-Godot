## [InputActionDef] for normalized directional input
class_name InputActionDefStickPad extends InputActionDef

@export_group("Default Bindings")
@export var mouse_motion: bool = false
@export var joy_motion: JoypadMotion

@export_group("Up", "up_")
@export var up_mouse_key_button: MouseKeyButton

@export_group("Down", "down_")
@export var down_mouse_key_button: MouseKeyButton

@export_group("Left", "left_")
@export var left_mouse_key_button: MouseKeyButton

@export_group("Right", "right_")
@export var right_mouse_key_button: MouseKeyButton

@export_group("Settings")
@export_range(0.0, 1.0, 0.01) var deadzone: float = 0.10
@export var invert_x: bool = false
@export var invert_y: bool = false

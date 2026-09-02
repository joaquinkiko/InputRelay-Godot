## [InputActionDef] for simple 4-way directional input
class_name InputActionDefDpad extends InputActionDef

@export_group("Default Bindings")
@export_group("Up", "up_")
@export var up_mouse_key_button: MouseKeyButton
@export var up_joy_button: JoypadButton

@export_group("Down", "down_")
@export var down_mouse_key_button: MouseKeyButton
@export var down_joy_button: JoypadButton

@export_group("Left", "left_")
@export var left_mouse_key_button: MouseKeyButton
@export var left_joy_button: JoypadButton

@export_group("Right", "right_")
@export var right_mouse_key_button: MouseKeyButton
@export var right_joy_button: JoypadButton

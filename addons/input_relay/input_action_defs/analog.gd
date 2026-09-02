## [InputActionDef] for analog actions like triggers
class_name InputActionDefAnalog extends InputActionDef

@export_group("Default Bindings")
@export var mouse_key_button: MouseKeyButton
@export var joy_button: JoypadButton

@export_group("Settings")
@export_range(0.0, 1.0, 0.01) var deadzone: float = 0.10

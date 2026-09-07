## [InputActionDef] for normalized directional input
class_name InputActionDefStickPad extends InputActionDefDirectional

@export_group("Default Bindings")
@export var mouse_motion: bool = false
@export var joy_motion: JoypadMotion

@export_group("Settings")
@export_range(0.0, 1.0, 0.01) var deadzone: float = 0.10
@export var invert_x: bool = false
@export var invert_y: bool = false

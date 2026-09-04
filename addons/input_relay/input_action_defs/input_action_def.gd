## Input action and bindings
@abstract
class_name InputActionDef extends Resource

enum MouseKeyButton{
	NONE,
	MOUSE_LEFT, MOUSE_RIGHT, MOUSE_MIDDLE,
	MOUSE_WHEEL_UP, MOUSE_WHEEL_DOWN, MOUSE_WHEEL_LEFT, MOUSE_WHEEL_RIGHT,
	MOUSE_EXTRA1, MOUSE_EXTRA2,
	A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
	KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9,
	APOSTROPHE, COMMA, MINUS, PERIOD, SLASH, SEMICOLON, EQUAL,
	BRACKETLEFT, BACKSLASH, BRACKETRIGHT, QUOTELEFT,
	SHIFT, CTRL, ALT, CAPSLOCK,
	LEFT, UP, RIGHT, DOWN, PAGEUP, PAGEDOWN,
	KP_0, KP_1, KP_2, KP_3, KP_4, KP_5, KP_6, KP_7, KP_8, KP_9,
	KP_MULTIPLY, KP_DIVIDE, KP_SUBTRACT, KP_PERIOD, KP_ADD, KP_ENTER,
	F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
	ESCAPE, TAB, BACKSPACE, ENTER, INSERT, DELETE, SPACE,
}

enum JoypadButton{
	NONE,
	SOUTH, EAST, WEST, NORTH,
	BACK, GUIDE, START,
	DPAD_UP, DPAD_DOWN, DPAD_LEFT, DPAD_RIGHT,
	LEFT_STICK_PRESS, RIGHT_STICK_PRESS,
	LEFT_SHOULDER, RIGHT_SHOULDER, LEFT_TRIGGER, RIGHT_TRIGGER,
	MISC1, MISC2, MISC3, MISC4, MISC5, MISC6,
	PADDLE1, PADDLE2, PADDLE3, PADDLE4,
	TOUCHPAD,
}

enum JoypadMotion{
	NONE,
	LEFT_STICK,
	RIGHT_STICK,
	GYRO,
}

## Converts a [MouseKeyButton] to a [Key]. Returns KEY_NONE if it's a mouse button.
static func mouse_key_button_to_key(button: MouseKeyButton) -> Key:
	match button:
		MouseKeyButton.A: return KEY_A
		MouseKeyButton.B: return KEY_B
		MouseKeyButton.C: return KEY_C
		MouseKeyButton.D: return KEY_D
		MouseKeyButton.E: return KEY_E
		MouseKeyButton.F: return KEY_F
		MouseKeyButton.G: return KEY_G
		MouseKeyButton.H: return KEY_H
		MouseKeyButton.I: return KEY_I
		MouseKeyButton.J: return KEY_J
		MouseKeyButton.K: return KEY_K
		MouseKeyButton.L: return KEY_L
		MouseKeyButton.M: return KEY_M
		MouseKeyButton.N: return KEY_N
		MouseKeyButton.O: return KEY_O
		MouseKeyButton.P: return KEY_P
		MouseKeyButton.Q: return KEY_Q
		MouseKeyButton.R: return KEY_R
		MouseKeyButton.S: return KEY_S
		MouseKeyButton.T: return KEY_T
		MouseKeyButton.U: return KEY_U
		MouseKeyButton.V: return KEY_V
		MouseKeyButton.W: return KEY_W
		MouseKeyButton.X: return KEY_X
		MouseKeyButton.Y: return KEY_Y
		MouseKeyButton.Z: return KEY_Z
		MouseKeyButton.KEY_0: return KEY_0
		MouseKeyButton.KEY_1: return KEY_1
		MouseKeyButton.KEY_2: return KEY_2
		MouseKeyButton.KEY_3: return KEY_3
		MouseKeyButton.KEY_4: return KEY_4
		MouseKeyButton.KEY_5: return KEY_5
		MouseKeyButton.KEY_6: return KEY_6
		MouseKeyButton.KEY_7: return KEY_7
		MouseKeyButton.KEY_8: return KEY_8
		MouseKeyButton.KEY_9: return KEY_9
		MouseKeyButton.APOSTROPHE: return KEY_APOSTROPHE
		MouseKeyButton.COMMA: return KEY_COMMA
		MouseKeyButton.MINUS: return KEY_MINUS
		MouseKeyButton.PERIOD: return KEY_PERIOD
		MouseKeyButton.SLASH: return KEY_SLASH
		MouseKeyButton.SEMICOLON: return KEY_SEMICOLON
		MouseKeyButton.EQUAL: return KEY_EQUAL
		MouseKeyButton.BRACKETLEFT: return KEY_BRACKETLEFT
		MouseKeyButton.BACKSLASH: return KEY_BACKSLASH
		MouseKeyButton.BRACKETRIGHT: return KEY_BRACKETRIGHT
		MouseKeyButton.QUOTELEFT: return KEY_QUOTELEFT
		MouseKeyButton.SHIFT: return KEY_SHIFT
		MouseKeyButton.CTRL: return KEY_CTRL
		MouseKeyButton.ALT: return KEY_ALT
		MouseKeyButton.CAPSLOCK: return KEY_CAPSLOCK
		MouseKeyButton.LEFT: return KEY_LEFT
		MouseKeyButton.UP: return KEY_UP
		MouseKeyButton.RIGHT: return KEY_RIGHT
		MouseKeyButton.DOWN: return KEY_DOWN
		MouseKeyButton.PAGEUP: return KEY_PAGEUP
		MouseKeyButton.PAGEDOWN: return KEY_PAGEDOWN
		MouseKeyButton.KP_0: return KEY_KP_0
		MouseKeyButton.KP_1: return KEY_KP_1
		MouseKeyButton.KP_2: return KEY_KP_2
		MouseKeyButton.KP_3: return KEY_KP_3
		MouseKeyButton.KP_4: return KEY_KP_4
		MouseKeyButton.KP_5: return KEY_KP_5
		MouseKeyButton.KP_6: return KEY_KP_6
		MouseKeyButton.KP_7: return KEY_KP_7
		MouseKeyButton.KP_8: return KEY_KP_8
		MouseKeyButton.KP_9: return KEY_KP_9
		MouseKeyButton.KP_MULTIPLY: return KEY_KP_MULTIPLY
		MouseKeyButton.KP_DIVIDE: return KEY_KP_DIVIDE
		MouseKeyButton.KP_SUBTRACT: return KEY_KP_SUBTRACT
		MouseKeyButton.KP_PERIOD: return KEY_KP_PERIOD
		MouseKeyButton.KP_ADD: return KEY_KP_ADD
		MouseKeyButton.KP_ENTER: return KEY_KP_ENTER
		MouseKeyButton.F1: return KEY_F1
		MouseKeyButton.F2: return KEY_F2
		MouseKeyButton.F3: return KEY_F3
		MouseKeyButton.F4: return KEY_F4
		MouseKeyButton.F5: return KEY_F5
		MouseKeyButton.F6: return KEY_F6
		MouseKeyButton.F7: return KEY_F7
		MouseKeyButton.F8: return KEY_F8
		MouseKeyButton.F9: return KEY_F9
		MouseKeyButton.F10: return KEY_F10
		MouseKeyButton.F11: return KEY_F11
		MouseKeyButton.F12: return KEY_F12
		MouseKeyButton.ESCAPE: return KEY_ESCAPE
		MouseKeyButton.TAB: return KEY_TAB
		MouseKeyButton.BACKSPACE: return KEY_BACKSPACE
		MouseKeyButton.ENTER: return KEY_ENTER
		MouseKeyButton.INSERT: return KEY_INSERT
		MouseKeyButton.DELETE: return KEY_DELETE
		MouseKeyButton.SPACE: return KEY_SPACE
		_: return KEY_NONE

## Converts a [MouseKeyButton] to a [MouseButton]. Returns MOUSE_BUTTON_NONE if it's a key.
static func mouse_key_button_to_mouse_button(button: MouseKeyButton) -> MouseButton:
	match button:
		MouseKeyButton.MOUSE_LEFT: return MOUSE_BUTTON_LEFT
		MouseKeyButton.MOUSE_RIGHT: return MOUSE_BUTTON_RIGHT
		MouseKeyButton.MOUSE_MIDDLE: return MOUSE_BUTTON_MIDDLE
		MouseKeyButton.MOUSE_WHEEL_UP: return MOUSE_BUTTON_WHEEL_UP
		MouseKeyButton.MOUSE_WHEEL_DOWN: return MOUSE_BUTTON_WHEEL_DOWN
		MouseKeyButton.MOUSE_WHEEL_LEFT: return MOUSE_BUTTON_WHEEL_LEFT
		MouseKeyButton.MOUSE_WHEEL_RIGHT: return MOUSE_BUTTON_WHEEL_RIGHT
		MouseKeyButton.MOUSE_EXTRA1: return MOUSE_BUTTON_XBUTTON1
		MouseKeyButton.MOUSE_EXTRA2: return MOUSE_BUTTON_XBUTTON2
		_: return MOUSE_BUTTON_NONE

## Converts a [JoypadButton] to Godot's [JoyButton]. Returns JOY_BUTTON_INVALID for
## triggers (use joypad_button_to_joy_axis).
static func joypad_button_to_joy_button(button: JoypadButton) -> JoyButton:
	match button:
		JoypadButton.SOUTH: return JOY_BUTTON_A
		JoypadButton.EAST: return JOY_BUTTON_B
		JoypadButton.WEST: return JOY_BUTTON_X
		JoypadButton.NORTH: return JOY_BUTTON_Y
		JoypadButton.BACK: return JOY_BUTTON_BACK
		JoypadButton.GUIDE: return JOY_BUTTON_GUIDE
		JoypadButton.START: return JOY_BUTTON_START
		JoypadButton.DPAD_UP: return JOY_BUTTON_DPAD_UP
		JoypadButton.DPAD_DOWN: return JOY_BUTTON_DPAD_DOWN
		JoypadButton.DPAD_LEFT: return JOY_BUTTON_DPAD_LEFT
		JoypadButton.DPAD_RIGHT: return JOY_BUTTON_DPAD_RIGHT
		JoypadButton.LEFT_STICK_PRESS: return JOY_BUTTON_LEFT_STICK
		JoypadButton.RIGHT_STICK_PRESS: return JOY_BUTTON_RIGHT_STICK
		JoypadButton.LEFT_SHOULDER: return JOY_BUTTON_LEFT_SHOULDER
		JoypadButton.RIGHT_SHOULDER: return JOY_BUTTON_RIGHT_SHOULDER
		JoypadButton.MISC1: return JOY_BUTTON_MISC1
		JoypadButton.MISC2: return JOY_BUTTON_MISC2
		JoypadButton.MISC3: return JOY_BUTTON_MISC3
		JoypadButton.MISC4: return JOY_BUTTON_MISC4
		JoypadButton.MISC5: return JOY_BUTTON_MISC5
		JoypadButton.MISC6: return JOY_BUTTON_MISC6
		JoypadButton.PADDLE1: return JOY_BUTTON_PADDLE1
		JoypadButton.PADDLE2: return JOY_BUTTON_PADDLE2
		JoypadButton.PADDLE3: return JOY_BUTTON_PADDLE3
		JoypadButton.PADDLE4: return JOY_BUTTON_PADDLE4
		JoypadButton.TOUCHPAD: return JOY_BUTTON_TOUCHPAD
		_: return JOY_BUTTON_INVALID

## Triggers report as an axis, not a digital button. Returns JOY_AXIS_INVALID otherwise.
static func joypad_button_to_joy_axis(button: JoypadButton) -> JoyAxis:
	match button:
		JoypadButton.LEFT_TRIGGER: return JOY_AXIS_TRIGGER_LEFT
		JoypadButton.RIGHT_TRIGGER: return JOY_AXIS_TRIGGER_RIGHT
		_: return JOY_AXIS_INVALID

## True if this MouseKeyButton belongs in the mouse table, false if it's a keyboard key
static func is_mouse_button(button: MouseKeyButton) -> bool:
	return button >= MouseKeyButton.MOUSE_LEFT && button <= MouseKeyButton.MOUSE_EXTRA2

## True if this JoypadButton is actually reported as an axis (triggers)
static func is_axis_button(button: JoypadButton) -> bool:
	return button == JoypadButton.LEFT_TRIGGER || button == JoypadButton.RIGHT_TRIGGER

## Converts a stick [JoypadMotion] to its [x, y] [JoyAxis] pair, if any
static func joypad_motion_to_joy_axes(motion: JoypadMotion) -> Array[JoyAxis]:
	match motion:
		JoypadMotion.LEFT_STICK: return [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]
		JoypadMotion.RIGHT_STICK: return [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]
		_: return []

## True if the value is a real MouseKeyButton enum entry
static func is_valid_mouse_key_button(button: int) -> bool:
	return MouseKeyButton.values().has(button)

## True if the value is a real JoypadButton enum entry
static func is_valid_joypad_button(button: int) -> bool:
	return JoypadButton.values().has(button)

## True if the value is a real JoypadMotion enum entry
static func is_valid_joypad_motion(motion: int) -> bool:
	return JoypadMotion.values().has(motion)

## Converts a MouseKeyButton to its enum name, for config file storage
static func mouse_key_button_to_string(button: MouseKeyButton) -> String:
	return MouseKeyButton.find_key(button)

## Converts an enum name back to a MouseKeyButton. Returns NONE if not found
static func string_to_mouse_key_button(string: String) -> MouseKeyButton:
	return MouseKeyButton.get(string, MouseKeyButton.NONE)

## Converts a JoypadButton to its enum name, for config file storage
static func joypad_button_to_string(button: JoypadButton) -> String:
	return JoypadButton.find_key(button)

## Converts an enum name back to a JoypadButton. Returns NONE if not found
static func string_to_joypad_button(string: String) -> JoypadButton:
	return JoypadButton.get(string, JoypadButton.NONE)

## Converts a JoypadMotion to its enum name, for config file storage
static func joypad_motion_to_string(motion: JoypadMotion) -> String:
	return JoypadMotion.find_key(motion)

## Converts an enum name back to a JoypadMotion. Returns NONE if not found
static func string_to_joypad_motion(string: String) -> JoypadMotion:
	return JoypadMotion.get(string, JoypadMotion.NONE)

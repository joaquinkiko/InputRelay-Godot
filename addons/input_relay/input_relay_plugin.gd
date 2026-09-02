@tool
extends EditorPlugin

func _enable_plugin() -> void:
	add_autoload_singleton("InputRelay", "input_relay.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("InputRelay")

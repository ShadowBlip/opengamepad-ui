extends PlatformProvider
class_name PlatformAyaneo2021


func get_handheld_gamepad() -> HandheldGamepad:
	return load("res://core/platform/ayaneo_gen1_gamepad.tres")
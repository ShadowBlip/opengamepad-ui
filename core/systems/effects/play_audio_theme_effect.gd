@tool
extends Effect
class_name PlayAudioThemeEffect

const DEFAULT_THEME := "res://assets/audio/themes/default.tres"

## The type of component that the audio theme should play
@export var type: AudioTheme.TYPE

@onready var theme := get_audio_theme()
@onready var audio_player := $AudioStreamPlayer as AudioStreamPlayer

func _ready() -> void:
	var on_finished := func():
		effect_finished.emit()
	audio_player.finished.connect(on_finished)
	audio_player.stream = stream


## Returns the audio theme
func get_audio_theme(current: Node = null) -> AudioTheme:
	if not current:
		current = self

	# If the current node has an audio theme, return it
	if current.has_meta("audio_theme"):
		return current.get_meta("audio_theme")

	# If this is the root node and no audio theme is defined, use the default
	if current == get_node("/root"):
		return load(DEFAULT_THEME)

	# Otherwise try to get the parent node's audio theme
	var parent := get_parent()

	return get_audio_theme(parent)


# Fires when the given signal is emitted
func _on_signal():
	play_sound()


func play_sound() -> void:
	audio_player.play()

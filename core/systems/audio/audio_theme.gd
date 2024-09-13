@icon("res://assets/editor-icons/icon-park-outline--sound-wave.svg")
extends Resource
class_name AudioTheme

## Resource for customizing the UI audio sounds

@export_category("General")
## Unique name of the audio theme
@export var name: String

@export_category("Global")
## Sounds to play when OpenGamepadUI first launches
@export_file("*.ogg") var intro := ""
## Sound to play when volume is increased
@export_file("*.ogg") var audio_volume_up := ""
## Sound to play when volume is decreased
@export_file("*.ogg") var audio_volume_down := ""
## Ambient background music to play in menus
@export_file("*.ogg") var ambient_music := ""
## Sound to play when a notification is displayed
@export_file("*.ogg") var notification_display := ""

@export_category("Side Menus")
## Sound to play when side menus (Main menu and QB menu) open
@export_file("*.ogg") var side_menu_open := ""
## Sound to play when side menus (Main menu and QB menu) close
@export_file("*.ogg") var side_menu_close := ""

@export_category("Button")
## Sound to play when button is focused
@export_file("*.ogg") var button_focus := "res://assets/audio/interface/536764__egomassive__toss.ogg"
## Sound to play when button is selected
@export_file("*.ogg") var button_select := "res://assets/audio/interface/96127__bmaczero__contact1.ogg"

@export_category("Slider")
## Sound to play when slider is focused
@export_file("*.ogg") var slider_focus := "res://assets/audio/interface/536764__egomassive__toss.ogg"
## Sound to play when slider value changes
@export_file("*.ogg") var slider_change := ""

@export_category("Toggle")
## Sound to play when toggle is focused
@export_file("*.ogg") var toggle_focus := "res://assets/audio/interface/536764__egomassive__toss.ogg"
## Sound to play when toggle value changes
@export_file("*.ogg") var toggle_change := ""

## Enumeration of all different components of an audio theme
enum TYPE {
	INTRO,
	AUDIO_VOLUME_UP,
	AUDIO_VOLUME_DOWN,
	AMBIENT_MUSIC,
	NOTIFICATION_DISPLAY,
	SIDE_MENU_OPEN,
	SIDE_MENU_CLOSE,
	BUTTON_FOCUS,
	BUTTON_SELECT,
	SLIDER_FOCUS,
	SLIDER_CHANGE,
	TOGGLE_FOCUS,
	TOGGLE_CHANGE,
}

## Returns the loaded audio stream for the given audio theme component type
func get_stream(type: TYPE) -> AudioStream:
	var path := ""
	match type:
		TYPE.INTRO:
			path = intro
		TYPE.AUDIO_VOLUME_UP:
			path = audio_volume_up
		TYPE.AUDIO_VOLUME_DOWN:
			path = audio_volume_down
	
	return null

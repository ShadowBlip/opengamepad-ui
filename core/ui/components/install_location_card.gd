extends Control
class_name InstallLocationCard

signal pressed
signal button_up
signal button_down

@onready var icon := $%IconTextureRect as TextureRect
@onready var name_label := $%DriveName as Label
@onready var desc_label := $%Description as Label
@onready var drive_size_label := $%DriveSize as Label
@onready var drive_used_bar := $%SpaceUsedProgressBar as ProgressBar
@onready var highlight := $%HighlightTexture as TextureRect

var location: Library.InstallLocation


## Creates an [InstallLocationCard] instance for the given install location
static func from_location(location: Library.InstallLocation) -> InstallLocationCard:
	var card_scene := load("res://core/ui/components/install_location_card.tscn") as PackedScene
	var card := card_scene.instantiate() as InstallLocationCard
	card.location = location

	return card


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not location:
		return
	if location.icon:
		icon.texture = location.icon

	name_label.text = location.name

	desc_label.visible = not location.description.is_empty()
	desc_label.text = location.description

	drive_size_label.visible = location.total_space_mb != 0
	drive_size_label.text = str(location.total_space_mb) + " Mb"

	drive_used_bar.visible = location.total_space_mb != 0
	var percent_free := (float(location.free_space_mb) / float(location.total_space_mb)) * 100.0
	drive_used_bar.value = 100.0 - percent_free

	# Find the parent theme and update if required
	var effective_theme := ThemeUtils.get_effective_theme(self)
	if effective_theme:
		_on_theme_changed()


func _on_theme_changed() -> void:
	# Configure the highlight texture from the theme
	var highlight_texture := get_theme_icon("highlight", "CardButton")
	if highlight_texture:
		highlight.texture = highlight_texture


func _gui_input(event: InputEvent) -> void:
	var dbus_path := event.get_meta("dbus_path", "") as String
	if event is InputEventMouseButton:
		if event.is_pressed():
			button_down.emit()
			pressed.emit()
		else:
			button_up.emit()
	if not event.is_action("ui_accept"):
		return
	if event.is_pressed():
		button_down.emit()
		pressed.emit()
	else:
		button_up.emit()

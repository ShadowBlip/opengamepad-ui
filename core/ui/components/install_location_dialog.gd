@icon("res://assets/editor-icons/solar--dialog-2-bold.svg")
@tool
extends Control
class_name InstallLocationDialog

## Emitted when the dialog window is opened
signal opened
## Emitted when the dialog window is closed
signal closed
## Emitted when the user selects an option
signal choice_selected(accepted: bool, location: Library.InstallLocation)

## Text to display in the dialog box
@export var text: String:
	set(v):
		text = v
		if label:
			label.text = v
## Cancel button text
@export var cancel_text: String = "Cancel":
	set(v):
		cancel_text = v
		if cancel_button:
			cancel_button.text = v
## Whether or not the cancel button should be shown
@export var cancel_visible: bool = true:
	set(v):
		cancel_visible = v
		if cancel_button:
			cancel_button.visible = v
## Close the dialog when the user selects an option
@export var close_on_selected := true
## Maximum size that the scroll container can grow to
@export var custom_maximum_size: Vector2i:
	set(v):
		custom_maximum_size = v
		if scroll_container:
			_recalculate_minimum_size()

@onready var scroll_container := $%ScrollContainer as ScrollContainer
@onready var content_container := $%ContentContainer as Container
@onready var label := $%Label as Label
@onready var cancel_button := $%CancelButton as CardButton
@onready var fade_effect := $%FadeEffect as Effect

var _return_node: Control = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cancel_button.button_up.connect(_on_selected.bind(false, null))
	scroll_container.sort_children.connect(_recalculate_minimum_size)


## Invoked when an item is selected
func _on_selected(accepted: bool, choice: Library.InstallLocation) -> void:
	if close_on_selected:
		closed.emit()
	choice_selected.emit(accepted, choice)
	if _return_node:
		_return_node.grab_focus.call_deferred()
	_return_node = null


## Updates the minimum size of the scroll container up to the custom_maximum_size.
## This will allow the scroll container to dynamically grow based on the content
## inside the scroll container up to a maximum size.
func _recalculate_minimum_size() -> void:
	if custom_maximum_size == Vector2i.ZERO:
		return
	if scroll_container.get_child_count() < 1:
		return

	# Scroll containers only support having one child node
	var child := scroll_container.get_child(0)
	if not child is Control:
		return
	var child_size := (child as Control).size

	# Check the size of the child to see if the max size has been reached. If not,
	# adjust the size of the scroll container based on the content.
	if custom_maximum_size.x != 0.0 and child_size.x > custom_maximum_size.x:
		scroll_container.custom_minimum_size.x = custom_maximum_size.x
	else:
		scroll_container.custom_minimum_size.x = child_size.x

	if custom_maximum_size.y != 0.0 and child_size.y > custom_maximum_size.y:
		scroll_container.custom_minimum_size.y = custom_maximum_size.y
	else:
		scroll_container.custom_minimum_size.y = child_size.y


## Opens the dialog box with the given settings
func open(return_node: Control, locations: Array[Library.InstallLocation] = [], message: String = "", cancel_txt: String = "") -> void:
	if message != "":
		text = message
	if cancel_txt != "":
		cancel_text = cancel_txt
	_return_node = return_node

	# Clear any old location cards
	for child in content_container.get_children():
		if not child is InstallLocationCard:
			continue
		content_container.remove_child(child)
		child.queue_free()

	# Create an install location card for each location
	var focus_node: Control = cancel_button
	for location in locations:
		var location_card := InstallLocationCard.from_location(location)
		if not location_card:
			continue
		content_container.add_child(location_card)
		content_container.move_child(location_card, -2)
		if focus_node == cancel_button:
			focus_node = location_card
		location_card.button_up.connect(_on_selected.bind(true, location))

	opened.emit()
	await fade_effect.effect_finished
	focus_node.grab_focus.call_deferred()

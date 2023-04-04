@icon("res://assets/icons/package.svg")
extends Resource
class_name LibraryItem

## LibraryItem is a high-level structure that contains data about a game.
##
## A LibraryItem is a single game title that may have one or more library 
## providers. It contains an array of [LibraryLaunchItem] resources that can 
## tell us how to launch a game.

## Is emitted when the [LibraryManager] adds this item to the library
signal added_to_library
## Is emitted when the [LibraryManager] removes this item from the library
signal removed_from_library

## The unique ID of the library item
@export var _id: String
## Name of the game
@export var name: String
## An array of [LibraryLaunchItem] resources that this game supports
@export var launch_items: Array = []
## An array of tags associated with this game
@export var tags: PackedStringArray
## An array of categories the game belongs to
@export var categories: PackedStringArray


## Creates a new library item from the given library launch item
static func new_from_launch_item(launch_item: LibraryLaunchItem) -> LibraryItem:
	var item: LibraryItem = LibraryItem.new()
	item.name = launch_item.name
	item.tags = launch_item.tags
	item.categories = launch_item.categories
	return item

## Returns the library launch item for the given provider. Returns null if the 
## given provider doesn't manage this game.
func get_launch_item(provider_id: String) -> LibraryLaunchItem:
	for i in launch_items:
		var launch_item: LibraryLaunchItem = i
		if launch_item._provider_id == provider_id:
			return launch_item
	return null


## Returns true if at least one library provider has this item installed.
func is_installed() -> bool:
	for i in launch_items:
		var launch_item: LibraryLaunchItem = i
		if launch_item.installed:
			return true
	return false

#  shortcutId: 123
#  name: Fortnite
#  command: steam
#  args: []
#  provider: steam
#  providerAppId: 1234
#  tags: []
#  categories: []
@icon("res://assets/editor-icons/library.svg")
extends Node
class_name Library

## Base class for Library implementations
## 
## The Library class provides an interface for creating new library 
## implementations. To create a new library, simply extend this class and 
## implement its methods. When a Library node is added to the scene tree, it 
## will automatically register itself with the global [LibraryManager].
##
## @tutorial:            https://github.com/ShadowBlip/OpenGamepadUI/blob/main/docs/plugins/TUTORIALS.md#writing-a-library-plugin

## Should be emitted when a library item is installed
signal install_completed(item: LibraryLaunchItem, success: bool)
## Should be emitted when a library item is updated
signal update_completed(item: LibraryLaunchItem, success: bool)
## Should be emitted when a library item is uninstalled
signal uninstall_completed(item: LibraryLaunchItem, success: bool)
## Should be emitted when a library item install is progressing
signal install_progressed(item: LibraryLaunchItem, percent_completed: float)
## Should be emitted when a new library item was added to the library
signal launch_item_added(item: LibraryLaunchItem)
## Should be emitted when a library item was removed from the library
signal launch_item_removed(item: LibraryLaunchItem)
## Should be emitted when a library item is moved to a different install location
signal move_completed(item: LibraryLaunchItem, success: bool)
## Should be emitted when a library item move is progressing
signal move_progressed(item: LibraryLaunchItem, percent_completed: float)

var LibraryManager := load("res://core/global/library_manager.tres") as LibraryManager # TODO: Remove this
var library_manager := load("res://core/global/library_manager.tres") as LibraryManager

## Unique identifier for the library
@export var library_id: String
## Optional store that this library is linked to
@export var store_id: String
## Icon for library provider
@export var library_icon: Texture2D
## Whether or not the library provider supports uninstalls
@export var supports_uninstall := true
## Logger name used for debug messages
@export var logger_name := library_id
## Log level of the logger.
@export var log_level: Log.LEVEL = Log.LEVEL.INFO

@onready var _cache_dir := "/".join(["library", library_id])
@onready var logger := Log.get_logger(logger_name, log_level)


func _init() -> void:
	add_to_group("library")
	ready.connect(library_manager.register_library.bind(self))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


## Returns an array of available library launch items that this library provides.
## This method should be overriden in the child class.
## Example:
##     [codeblock]
##     func get_library_launch_items() -> Array[LibraryLaunchItem]:
##             var item: LibraryLaunchItem = LibraryLaunchItem.new()
##             item.name = "vkCube"
##             item.command = "vkcube"
##             item.args = []
##             item.tags = ["vkcube"]
##             item.installed = true
##     
##             return [item]
##     [/codeblock]
func get_library_launch_items() -> Array[LibraryLaunchItem]:
	return []


## Returns an array of available install locations for this library provider.
## This method should be overridden in the child class.
## Example:
##   [codeblock]
##   func get_available_install_locations() -> Array[InstallLocation]:
##       var location := InstallLocation.new()
##       location.name = "/"
##       return [location]
##   [/codeblock]
func get_available_install_locations(item: LibraryLaunchItem = null) -> Array[InstallLocation]:
	return []


## Returns an array of install options for the given [LibraryLaunchItem].
## Install options are arbitrary and are provider-specific. They allow the user
## to select things like the language of a game to install, etc.
## Example:
##   [codeblock]
##   func get_install_options(item: LibraryLaunchItem) -> Array[InstallOption]:
##       var option := InstallOption.new()
##       option.id = "lang"
##       option.name = "Language"
##       option.description = "Language of the game to install"
##       option.values = ["english", "spanish"]
##       option.value_type = TYPE_STRING
##       return [option]
##   [/codeblock]
func get_install_options(item: LibraryLaunchItem) -> Array[InstallOption]:
	return []


## This method should be overridden if the library requires executing callbacks
## at certain points in an app's lifecycle, such as when an app is starting or
## stopping.
func get_app_lifecycle_hooks() -> Array[AppLifecycleHook]:
	var hooks: Array[AppLifecycleHook]
	return hooks


## [DEPRECATED]
## Installs the given library item. This method should be overriden in the 
## child class, if it supports it.
func install(item: LibraryLaunchItem) -> void:
	pass


## Installs the given library item to the given location. This method should be
## overridden in the child class, if it supports it.
func install_to(item: LibraryLaunchItem, location: InstallLocation = null, options: Dictionary = {}) -> void:
	install(item)


## Updates the given library item. This method should be overriden in the 
## child class, if it supports it.
func update(item: LibraryLaunchItem) -> void:
	pass


## Should return true if the given library item has an update available
func has_update(item: LibraryLaunchItem) -> bool:
	return false


## Uninstalls the given library item. This method should be overriden in the 
## child class if it supports it.
func uninstall(item: LibraryLaunchItem) -> void:
	pass


## Move the given library item to the given install location. This method should
## be overriden in the child class if it supports it.
func move(item: LibraryLaunchItem, to_location: InstallLocation) -> void:
	pass


func _exit_tree() -> void:
	library_manager.unregister_library(self)


## InstallLocation defines a place where a [LibraryLaunchItem] can be installed.
class InstallLocation extends RefCounted:
	var id: String
	var name: String
	var description: String
	var icon: Texture2D
	var total_space_mb: int
	var free_space_mb: int


## InstallOption defines an arbitrary install option for a [LibraryLaunchitem].
class InstallOption extends RefCounted:
	var id: String
	var name: String
	var description: String
	var values: Array[Variant]
	var value_type: int

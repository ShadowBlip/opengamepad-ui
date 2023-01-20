extends Control

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var home_state := preload("res://assets/state/states/home.tres") as State
var poster_scene := preload("res://core/ui/components/poster.tscn") as PackedScene
var state_changer_scene := preload("res://core/systems/state/state_changer.tscn") as PackedScene

@onready var library_manager: LibraryManager = get_node("/root/Main/LibraryManager")
@onready var launch_manager: LaunchManager = get_node("/root/Main/LaunchManager")
@onready var boxart_manager: BoxArtManager = get_node("/root/Main/BoxArtManager")
@onready var container: HBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MarginContainer/HBoxContainer
@onready var banner: TextureRect = $SelectedBanner
@onready var player: AnimationPlayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	library_manager.library_reloaded.connect(_on_recent_apps_updated)
	launch_manager.recent_apps_changed.connect(_on_recent_apps_updated)
	home_state.state_entered.connect(_on_home_state_entered)
	home_state.state_exited.connect(_on_home_state_exited)


func _on_home_state_entered(from: State) -> void:
	visible = true
	_grab_focus()
	
	
func _on_home_state_exited(to: State) -> void:
	visible = state_machine.has_state(home_state)
	
	
func _on_recent_apps_updated():
	# Clear any old grid items
	for child in container.get_children():
		if child.name == "LibraryPoster":
			continue
		container.remove_child(child)
		child.queue_free()
	
	# Get the list of recent apps from LaunchManager
	var recent_apps: Array = launch_manager.get_recent_apps()
	
	# Get library items from the library manager
	# NOTE: Weirdly, Godot does not like pushing Resource objects to an array
	var items: Dictionary = {}
	for n in recent_apps:
		var name: String = n
		var library_item: LibraryItem = library_manager.get_app_by_name(name)
		if library_item == null:
			continue
		items[name] = library_item
	
	# Populate our grid with items
	_populate_grid(container, items.values())
	_grab_focus()


func _grab_focus():
	for child in container.get_children():
		child.grab_focus.call_deferred()
		break


# Called when a poster is focused
func _on_poster_focused(item: LibraryItem):
	player.stop()
	player.play("fade_in")
	banner.texture = await boxart_manager.get_boxart_or_placeholder(item, BoxArtManager.Layout.BANNER)


func _on_poster_boxart_loaded(texture: Texture2D, poster: TextureButton):
	poster.texture_normal = texture


# Populates the given grid with library items
func _populate_grid(grid: HBoxContainer, library_items: Array):
	var i: int = 0
	for entry in library_items:
		var item: LibraryItem = entry

		# Build a poster for each library item
		var poster: TextureButton = poster_scene.instantiate()
		poster.library_item = item
		if i == 0:
			poster.layout = poster.LAYOUT_MODE.LANDSCAPE
		else:
			poster.layout = poster.LAYOUT_MODE.PORTRAIT
		poster.text = item.name

		# Get the boxart for the item
		var layout = BoxArtManager.Layout.GRID_PORTRAIT
		if poster.layout == poster.LAYOUT_MODE.LANDSCAPE:
			layout = BoxArtManager.Layout.GRID_LANDSCAPE
		poster.texture_normal = await boxart_manager.get_boxart_or_placeholder(item, layout)
		
		# Listen for focus events on the posters
		poster.focus_entered.connect(_on_poster_focused.bind(item))

		# Build a launcher from the library item
		var state_changer: StateChanger = state_changer_scene.instantiate()
		state_changer.signal_name = "button_up"
		state_changer.state = StateManager.STATE.GAME_LAUNCHER
		state_changer.action = StateChanger.Action.PUSH
		state_changer.data = {"item": item}
		poster.add_child(state_changer)

		# Add the poster to the grid
		grid.add_child(poster)
		i += 1

	# Move our Library Poster to the back
	var library_poster: Node = grid.get_node("LibraryPoster")
	grid.move_child(library_poster, -1)

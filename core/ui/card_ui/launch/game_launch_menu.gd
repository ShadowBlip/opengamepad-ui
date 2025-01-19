extends Control

var SettingsManager := preload("res://core/global/settings_manager.tres")
var LaunchManager := preload("res://core/global/launch_manager.tres")
var NotificationManager := preload("res://core/global/notification_manager.tres")
var BoxArtManager := preload("res://core/global/boxart_manager.tres")
var LibraryManager := preload("res://core/global/library_manager.tres")
var InstallManager := preload("res://core/global/install_manager.tres")

var state_machine := (
	preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
)
var launcher_state := preload("res://assets/state/states/game_launcher.tres") as State
var in_game_state := preload("res://assets/state/states/in_game.tres") as State
var game_settings_state := preload("res://assets/state/states/game_settings.tres") as State
var gamepad_settings_state := preload("res://assets/state/states/gamepad_settings.tres") as State
var logger := Log.get_logger("GameLaunchMenu")

@export var launch_item: LibraryLaunchItem

@onready var banner := $%BannerTexture as TextureRect
@onready var logo := $%LogoTexture as TextureRect
@onready var launch_button := $%LaunchButton as CardButton
@onready var loading := $%LoadingAnimation as Control
@onready var player := $%AnimationPlayer as AnimationPlayer
@onready var progress_container := $%ProgressContainer as MarginContainer
@onready var progress_bar := $%ProgressBar as ProgressBar
@onready var delete_container := $%DeleteContainer as MarginContainer
@onready var delete_button := $%DeleteButton as CardIconButton
@onready var location_menu := $%InstallLocationDialog as InstallLocationDialog
@onready var options_menu := $%InstallOptionsDialog as InstallOptionDialog


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	launcher_state.state_entered.connect(_on_state_entered)
	launcher_state.state_exited.connect(_on_state_exited)
	launch_button.button_up.connect(_on_launch)
	delete_button.button_up.connect(_on_uninstall)


# Ensure the launcher elements are up-to-date with any installs going on
func _process(_delta: float) -> void:
	_update_launch_button()
	_update_uninstall_button()
	if not launch_item or not InstallManager.is_installing(launch_item):
		launch_button.disabled = false
		progress_container.visible = false
		return
	var req := InstallManager.get_installing()
	launch_button.disabled = true
	progress_container.visible = true
	progress_bar.value = req.progress * 100


func _on_state_entered(_from: State) -> void:
	# Fade in the banner texture
	player.play("fade_in")

	# Ensure dialogs are hidden
	location_menu.visible = false
	options_menu.visible = false

	# Focus the first entry on state change
	launch_button.grab_focus.call_deferred()

	# Get the library item from the data passed by the state change
	if not "item" in launcher_state.data:
		logger.error("No library item found to configure launcher!")
		return

	# Configure the game launch menu based on the library item provider
	var library_item: LibraryItem = launcher_state.data["item"]
	var provider := library_item.launch_items[0] as LibraryLaunchItem
	var section := "game.{0}".format([library_item.name.to_lower()])
	var provider_id = SettingsManager.get_value(section, "provider", "")
	if provider_id != "":
		var p := library_item.get_launch_item(provider_id)
		if p != null:
			provider = p
	launch_item = provider
	logger.info("Configured launcher for game: " + library_item.name)
	set_process(true)
	
	# Configure the game settings state with this game
	game_settings_state.data = launcher_state.data

	# Configure the controller settings state with this game 
	gamepad_settings_state.data = launcher_state.data ## DEPRECATED, use meta
	gamepad_settings_state.set_meta("item", library_item)

	# Check if the app is installed or not
	_update_launch_button()

	# Set the launcher art to placeholders while we async load the right ones.
	banner.texture = BoxArtManager.get_placeholder(BoxArtProvider.LAYOUT.BANNER)
	logo.texture = BoxArtManager.get_placeholder(BoxArtProvider.LAYOUT.LOGO)

	# Play a loading animation while the art loads
	loading.visible = true

	# Load the banner for the game
	var logo_texture = await (
		BoxArtManager.get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.LOGO)
	)
	logo.texture = logo_texture
	var banner_texture = await (
		BoxArtManager.get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.BANNER)
	)
	banner.texture = banner_texture

	loading.visible = false


func _on_state_exited(to: State) -> void:
	if to != gamepad_settings_state:
		gamepad_settings_state.remove_meta("item")
	if to == in_game_state:
		state_machine.remove_state(launcher_state)
	set_process(false)


func _update_launch_button() -> void:
	if not launch_item:
		return
	if launch_item.installed:
		launch_button.text = tr("Play Now")
	else:
		launch_button.text = tr("Install")
	if LaunchManager.is_running(launch_item.name):
		launch_button.text = tr("Resume")
	if InstallManager.is_queued(launch_item):
		launch_button.text = tr("Queued")
	if InstallManager.is_installing(launch_item):
		launch_button.text = tr("Installing")


func _update_uninstall_button() -> void:
	if not launch_item:
		return
	if not launch_item.installed:
		delete_container.visible = false
		return
	var provider := LibraryManager.get_library_by_id(launch_item._provider_id)
	if not provider.supports_uninstall:
		delete_container.visible = false
		return
	delete_container.visible = true


func _on_launch() -> void:
	# Resume if the game is running already
	if LaunchManager.is_running(launch_item.name):
		state_machine.set_state([in_game_state])
		return

	# If the app isn't installed, install it.
	if not launch_item.installed:
		_on_install()
		return

	# Launch the game using launch manager
	LaunchManager.launch(launch_item)


func _on_install() -> void:
	# Do nothing if we're already installing
	if InstallManager.is_queued_or_installing(launch_item):
		return

	# Get the library provider for this launch item
	var provider := LibraryManager.get_library_by_id(launch_item._provider_id)

	# If multiple install locations are available, ask the user where to
	# install.
	var location: Library.InstallLocation = null
	var locations := await provider.get_available_install_locations(launch_item)
	if locations.size() > 0:
		# Open the install location menu and wait for the user to select an
		# install location.
		location_menu.open(launch_button, locations)
		var result := await location_menu.choice_selected as Array
		var accepted := result[0] as bool
		var choice := result[1] as Library.InstallLocation
		if not accepted:
			return
		location = choice
	
	# If install options are available for this library item, ask the user
	# to select from the options.
	var options := {}
	var available_options := await provider.get_install_options(launch_item)
	if available_options.size() > 0:
		# Open the install option menu and wait for the user to select install
		# options.
		options_menu.open(launch_button, available_options)
		var result := await options_menu.choice_selected as Array
		var accepted := result[0] as bool
		var choices := result[1] as Dictionary
		if not accepted:
			return
		options = choices
	
	# Create an install request
	var install_req := InstallManager.Request.new(provider, launch_item, location, options)

	# Update the progress bar with install progress of the request
	progress_bar.value = 0

	# Display a notification
	var notify := Notification.new("Installing " + launch_item.name)
	NotificationManager.show(notify)

	# Start the install
	InstallManager.install(install_req)

	# Show a notification when install completes
	var on_installed := func(success: bool):
		var verb: String
		if success:
			verb = "completed"
			install_req.item.installed = true
		else:
			verb = "failed"
		var install_msg := Notification.new("Install " + verb + " for " + install_req.item.name)
		NotificationManager.show(install_msg)
	install_req.completed.connect(on_installed, CONNECT_ONE_SHOT)


func _on_uninstall() -> void:
	# Do nothing if we're already installing
	if InstallManager.is_queued_or_installing(launch_item):
		return
	var notify := Notification.new("Uninstalling " + launch_item.name)
	NotificationManager.show(notify)

	# Create an uninstall request
	var provider := LibraryManager.get_library_by_id(launch_item._provider_id)
	var uninstall_req := InstallManager.Request.new(provider, launch_item)

	# Show a notification when uninstall completes
	var on_uninstalled := func(success: bool):
		var verb: String
		if success:
			verb = "completed"
			uninstall_req.item.installed = false
		else:
			verb = "failed"
		var uninstall_msg := Notification.new("Uninstall " + verb + " for " + uninstall_req.item.name)
		NotificationManager.show(uninstall_msg)
	uninstall_req.completed.connect(on_uninstalled, CONNECT_ONE_SHOT)

	# Start the uninstall
	InstallManager.uninstall(uninstall_req)

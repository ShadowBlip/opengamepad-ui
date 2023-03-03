extends Control

const system_thread := preload("res://core/systems/threading/system_thread.tres")
const bar_0 := preload("res://assets/ui/icons/wifi-none.svg")
const bar_1 := preload("res://assets/ui/icons/wifi-low.svg")
const bar_2 := preload("res://assets/ui/icons/wifi-medium.svg")
const bar_3 := preload("res://assets/ui/icons/wifi-high.svg")

var connecting := false
@onready var wifi_tree := $%WifiNetworkTree as Tree
@onready var refresh_button := $%RefreshButton as Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	system_thread.start()
	visibility_changed.connect(_on_visible_changed)
	refresh_button.pressed.connect(_refresh_networks)
	wifi_tree.item_activated.connect(_on_wifi_selected)
	wifi_tree.create_item()


func _on_visible_changed() -> void:
	_refresh_networks()


func _on_wifi_selected() -> void:
	if connecting:
		return
	connecting = true
	refresh_button.disabled = true

	var item := wifi_tree.get_selected()
	var ssid := item.get_text(1)
	var connect_ap := func() -> int:
		return NetworkManager.connect_access_point(ssid)
	item.set_text(4, "Connecting")
	var code := await system_thread.exec(connect_ap) as int

	connecting = false
	refresh_button.disabled = false
	if code == OK:
		_refresh_networks()
		return
	# TODO: Open prompt for password
	item.set_text(4, "Failed to connect")


func _refresh_networks() -> void:
	# Disable the refresh button while refreshing
	refresh_button.disabled = true

	# Fetch all the available access points from NetworkManager
	var tree := wifi_tree as Tree
	var root := tree.get_root()
	var access_points: Array[NetworkManager.WifiAP]
	var get_aps := func() -> Array[NetworkManager.WifiAP]:
		return NetworkManager.get_access_points()
	access_points = await system_thread.exec(get_aps)

	# Create an array of BSSIDs from our access points
	var bssids := []
	for ap in access_points:
		bssids.append(ap.bssid)

	# Look at the current tree items to see if any need to be removed
	var tree_bssids := {}
	for item in root.get_children():
		var bssid := item.get_metadata(0) as String
		if bssid in bssids:
			tree_bssids[bssid] = item
			continue
		root.remove_child(item)

	# Look at the current APs to see if any tree items need to be created
	# or updated
	for ap in access_points:
		var item: TreeItem
		if ap.bssid in tree_bssids:
			item = tree_bssids[ap.bssid]
		else:
			item = tree.create_item(root)
		item.set_metadata(0, ap.bssid)
		item.set_icon(0, _get_strength_texture(ap.strength))
		item.set_text(1, ap.ssid)
		item.set_text(2, ap.security)
		item.set_text(3, ap.rate)
		if ap.in_use:
			item.set_text(4, "Connected")
		else:
			item.set_text(4, "")

	refresh_button.disabled = false


func _get_strength_texture(strength: int) -> Texture2D:
	if strength >= 80:
		return bar_3
	if strength >= 60:
		return bar_2
	if strength >= 40:
		return bar_1
	return bar_0

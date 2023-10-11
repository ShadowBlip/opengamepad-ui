extends Test

var network_manager := load("res://core/systems/network/network_manager.tres") as NetworkManager

func _ready() -> void:
	if not network_manager.supports_network():
		return

	print("Connectivity: ", network_manager.connectivity)
	print("Networking enabled: ", network_manager.networking_enabled)
	print("Wireless enabled: ", network_manager.wireless_enabled)

	var devices := network_manager.get_devices_by_type(NetworkManager.DEVICE_TYPE.WIFI)
	for device in devices:
		print(device.interface)
		if device is NetworkManager.WirelessDevice:
			print("Device is a wifi device")
			print(" Path: ", device.get_object_path())
			device.request_scan()
			for ap in device.get_all_access_points():
				print("Found AP: ", ap.ssid)
				print(" Path: ", ap.get_object_path())
	

	#for ap in NetworkManager.get_access_points():
	#	logger.info(ap.ssid + " " + str(ap.strength))

	#for device in NetworkManager.get_devices():
	#	logger.info(device.device + " " + device.type + " " + device.state)

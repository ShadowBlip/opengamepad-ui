extends Resource
class_name NetworkManager

## Manage and interact with the system network settings
##
## Allows network management through dbus
## https://people.freedesktop.org/~lkundrak/nm-docs/gdbus-org.freedesktop.NetworkManager.html

signal updated

const bar_0 := preload("res://assets/ui/icons/wifi-none.svg")
const bar_1 := preload("res://assets/ui/icons/wifi-low.svg")
const bar_2 := preload("res://assets/ui/icons/wifi-medium.svg")
const bar_3 := preload("res://assets/ui/icons/wifi-high.svg")

const NM_BUS := "org.freedesktop.NetworkManager"
const NM_PREFIX := "/org/freedesktop/NetworkManager"
const IFACE_NETWORK_MANAGER := "org.freedesktop.NetworkManager"
const IFACE_ACCESS_POINT := "org.freedesktop.NetworkManager.AccessPoint"
const IFACE_DEVICE := "org.freedesktop.NetworkManager.Device"
const IFACE_WIRELESS := "org.freedesktop.NetworkManager.Device.Wireless"
const IFACE_WIRED := "org.freedesktop.NetworkManager.Device.Wired"

enum CONNECTIVITY_STATE {
	UNKNOWN = 1,
	NONE = 2,
	PORTAL = 3,
	LIMITED = 4,
	FULL = 5,
}

enum DEVICE_TYPE {
	UNKNOWN = 0,
	GENERIC = 14,
	ETHERNET = 1,
	WIFI = 2,
	UNUSED_1 = 3,
	UNUSED_2 = 4,
	BT = 5,
	OLPC_MESH = 6,
	WIMAX = 7,
	MODEM = 8,
	INFINIBAND = 9,
	BOND = 10,
	VLAN = 11,
	ADSL = 12,
	BRIDGE = 13,
	TEAM = 15,
	TUN = 16,
	IP_TUNNEL = 17,
	MACVLAN = 18,
	VXLAN = 19,
	VETH = 20,
}

## https://people.freedesktop.org/~lkundrak/nm-docs/nm-dbus-types.html#NMDeviceState
enum DEVICE_STATE {
	UNKNOWN = 0,
	UNMANAGED = 10,
	UNAVAILABLE = 20,
	DISCONNECTED = 30,
	PREPARE = 40,
	CONFIG = 50,
	NEED_AUTH = 60,
	IP_CONFIG = 70,
	IP_CHECK = 80,
	SECONDARIES = 90,
	ACTIVATED = 100,
	DEACTIVATING = 110,
	FAILED = 120,
}

var dbus := load("res://core/global/dbus_system.tres") as DBusManager
var _proxy := dbus.create_proxy(NM_BUS, NM_PREFIX)
var connectivity: int:
	get:
		var property = _proxy.get_property(IFACE_NETWORK_MANAGER, "Connectivity")
		if not property is int:
			return 0
		return property
var networking_enabled: bool:
	get:
		var property = _proxy.get_property(IFACE_NETWORK_MANAGER, "NetworkingEnabled")
		if not property is bool:
			return false
		return property
var wireless_enabled: bool:
	set(v):
		_proxy.set_property(IFACE_NETWORK_MANAGER, "WirelessEnabled", v)
	get:
		var property = _proxy.get_property(IFACE_NETWORK_MANAGER, "WirelessEnabled")
		if not property is bool:
			return false
		return property


func _init() -> void:
	_proxy.properties_changed.connect(_on_properties_changed)


func _on_properties_changed(_iface: String, _props: Dictionary) -> void:
	updated.emit()


## Returns true if the system has network controls we support
func supports_network() -> bool:
	return dbus.bus_exists(NM_BUS)


## Control whether overall networking is enabled or disabled. When disabled, 
## all interfaces that NM manages are deactivated. When enabled, all managed 
## interfaces are re-enabled and available to be activated. This command should 
## be used by clients that provide to users the ability to enable/disable all 
## networking. 
func enable(enabled: bool) -> void:
	_proxy.call_method(IFACE_NETWORK_MANAGER, "Enable", [enabled], "b")


## Control the NetworkManager daemon's sleep state. When asleep, all interfaces 
## that it manages are deactivated. When awake, devices are available to be 
## activated. This command should not be called directly by users or clients; it
## is intended for system suspend/resume tracking. 
func sleep(enabled: bool) -> void:
	_proxy.call_method(IFACE_NETWORK_MANAGER, "Sleep", [enabled], "b")


## Activate a connection using the supplied device.
func activate_connection():
	pass


## List of object paths of network devices known to the system. This list does 
## not include device placeholders (see GetAllDevices()).
func get_device_paths() -> PackedStringArray:
	var result := _proxy.call_method(IFACE_NETWORK_MANAGER, "GetDevices")
	var args := result.get_args()
	if args.size() != 1:
		return PackedStringArray()
	if not args[0] is Array:
		return PackedStringArray()
	return PackedStringArray(args[0])


## List of object paths of network devices and device placeholders (eg, devices 
## that do not yet exist but which can be automatically created by NetworkManager 
## if one of their AvailableConnections was activated).
func get_all_devices_paths() -> PackedStringArray:
	var result := _proxy.call_method(IFACE_NETWORK_MANAGER, "GetAllDevices")
	var args := result.get_args()
	if args.size() != 1:
		return PackedStringArray()
	if not args[0] is Array:
		return PackedStringArray()
	return PackedStringArray(args[0])


## Return a list of [Device] objects detected by NetworkManager
func get_devices() -> Array[Device]:
	return get_devices_from_paths(get_device_paths())


## Return a list of [Device] objects detected by NetworkManager
func get_devices_by_type(type: DEVICE_TYPE) -> Array[Device]:
	var devices: Array[Device] = []
	for device in get_devices():
		if device.type == type:
			devices.append(device)
	return devices


## Return a list of all [Device] objects, even those not created yet
func get_all_devices() -> Array[Device]:
	return get_devices_from_paths(get_all_devices_paths())


## Return a list of all [Device] objects, even those not created yet
func get_all_devices_by_type(type: DEVICE_TYPE) -> Array[Device]:
	var devices: Array[Device] = []
	for device in get_all_devices():
		if device.type == type:
			devices.append(device)
	return devices


## Return a list of [Device] objects from the given DBus paths
func get_devices_from_paths(paths: PackedStringArray) -> Array[Device]:
	var devices: Array[Device] = []
	for path in paths:
		var proxy := dbus.create_proxy(NM_BUS, path)
		var device := Device.new(proxy)
		if device.type == DEVICE_TYPE.WIFI:
			device = WirelessDevice.new(proxy)
		devices.append(device)
	
	return devices


## Returns the texture reflecting the given wifi strength
static func get_strength_texture(strength: int) -> Texture2D:
	if strength >= 80:
		return bar_3
	if strength >= 60:
		return bar_2
	if strength >= 40:
		return bar_1
	return bar_0


## Container for NetworkManager devices
## https://people.freedesktop.org/~lkundrak/nm-docs/gdbus-org.freedesktop.NetworkManager.Device.html
class Device extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy
	var interface: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Interface")
			if not property is String:
				return ""
			return property
	var ip_interface: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "IpInterface")
			if not property is String:
				return ""
			return property
	var driver: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Driver")
			if not property is String:
				return ""
			return property
	var driver_version: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "DriverVersion")
			if not property is String:
				return ""
			return property
	var firmware_version: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "FirmwareVersion")
			if not property is String:
				return ""
			return property
	var capabilities: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Capabilities")
			if not property is int:
				return 0
			return property
	var state: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "State")
			if not property is int:
				return 0
			return property
	var type: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "DeviceType")
			if not property is int:
				return 0
			return property
	var active_connection_path: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "ActiveConnection")
			if not property is String:
				return ""
			return property
	var ip4_config_path: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Ip4Config")
			if not property is String:
				return ""
			return property
			
	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(_iface: String, _props: Dictionary) -> void:
		updated.emit()
	
	func get_object_path() -> String:
		return _proxy.path


## https://people.freedesktop.org/~lkundrak/nm-docs/gdbus-org.freedesktop.NetworkManager.Device.Wireless.html
class WirelessDevice extends Device:
	signal access_point_added
	signal access_point_removed
	var hw_address: String:
		get:
			var property = _proxy.get_property(IFACE_WIRELESS, "HwAddress")
			if not property is String:
				return ""
			return property
	var perm_hw_address: String:
		get:
			var property = _proxy.get_property(IFACE_WIRELESS, "PermHwAddress")
			if not property is String:
				return ""
			return property
	var mode: int:
		get:
			var property = _proxy.get_property(IFACE_WIRELESS, "Mode")
			if not property is int:
				return 0
			return property
	var bitrate: int:
		get:
			var property = _proxy.get_property(IFACE_WIRELESS, "Bitrate")
			if not property is int:
				return 0
			return property
	var access_point_paths: PackedStringArray:
		get:
			var property = _proxy.get_property(IFACE_WIRELESS, "AccessPoints")
			if not property is Array:
				return []
			return PackedStringArray(property)
	var access_points: Array[AccessPoint]:
		get:
			var aps: Array[AccessPoint] = []
			var dbus := load("res://core/global/dbus_system.tres") as DBusManager
			for path in access_point_paths:
				var proxy := dbus.create_proxy(NM_BUS, path)
				var ap := AccessPoint.new(proxy)
				aps.append(ap)
			return aps
	var active_access_point_path: String:
		get:
			var property = _proxy.get_property(IFACE_WIRELESS, "ActiveAccessPoint")
			if not property is String:
				return ""
			return property
	var active_access_point: AccessPoint:
		get:
			var path = _proxy.get_property(IFACE_WIRELESS, "ActiveAccessPoint")
			if not path is String:
				return null
			var dbus := load("res://core/global/dbus_system.tres") as DBusManager
			var proxy := dbus.create_proxy(NM_BUS, path)
			return AccessPoint.new(proxy)
	var wireless_capabilities: int:
		get:
			var property = _proxy.get_property(IFACE_WIRELESS, "WirelessCapabilities")
			if not property is int:
				return 0
			return property

	func get_all_access_point_paths() -> PackedStringArray:
		var response := _proxy.call_method(IFACE_WIRELESS, "GetAllAccessPoints")
		if not response:
			return PackedStringArray()
		var args := response.get_args()
		if args.size() == 0:
			return PackedStringArray()
		
		return PackedStringArray(args[0])

	func get_all_access_points() -> Array[AccessPoint]:
		var paths := get_all_access_point_paths()
		var aps: Array[AccessPoint] = []
		var dbus := load("res://core/global/dbus_system.tres") as DBusManager
		for path in paths:
			var proxy := dbus.create_proxy(NM_BUS, path)
			var ap := AccessPoint.new(proxy)
			aps.append(ap)
		return aps

	func request_scan(options: Dictionary = {}) -> void:
		_proxy.call_method(IFACE_WIRELESS, "RequestScan", [options], "a{sv}")
	
	func get_object_path() -> String:
		return _proxy.path


## https://people.freedesktop.org/~lkundrak/nm-docs/gdbus-org.freedesktop.NetworkManager.IP4Config.html
class IP4Config extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(_iface: String, _props: Dictionary) -> void:
		updated.emit()
	
	func get_object_path() -> String:
		return _proxy.path


## https://people.freedesktop.org/~lkundrak/nm-docs/gdbus-org.freedesktop.NetworkManager.AccessPoint.html
class AccessPoint extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy
	var flags: int:
		get:
			var property = _proxy.get_property(IFACE_ACCESS_POINT, "Flags")
			if not property is int:
				return 0
			return property
	var wpa_flags: int:
		get:
			var property = _proxy.get_property(IFACE_ACCESS_POINT, "WpaFlags")
			if not property is int:
				return 0
			return property
	var rsn_flags: int:
		get:
			var property = _proxy.get_property(IFACE_ACCESS_POINT, "RsnFlags")
			if not property is int:
				return 0
			return property
	var ssid: String:
		get:
			return ssid_bytes.get_string_from_utf8()
	var ssid_bytes: PackedByteArray:
		get:
			var property = _proxy.get_property(IFACE_ACCESS_POINT, "Ssid")
			if not property is Array:
				return PackedByteArray()
			return PackedByteArray(property)
	var frequency: int:
		get:
			var property = _proxy.get_property(IFACE_ACCESS_POINT, "Frequency")
			if not property is int:
				return 0
			return property
	var hw_address: String:
		get:
			var property = _proxy.get_property(IFACE_ACCESS_POINT, "HwAddress")
			if not property is String:
				return ""
			return property
	var mode: int:
		get:
			var property = _proxy.get_property(IFACE_ACCESS_POINT, "Mode")
			if not property is int:
				return 0
			return property
	var max_bitrate: int:
		get:
			var property = _proxy.get_property(IFACE_ACCESS_POINT, "MaxBitrate")
			if not property is int:
				return 0
			return property
	var strength: int:
		get:
			var property = _proxy.get_property(IFACE_ACCESS_POINT, "Strength")
			if not property is int:
				return 0
			return property
	var last_seen: int:
		get:
			var property = _proxy.get_property(IFACE_ACCESS_POINT, "LastSeen")
			if not property is int:
				return 0
			return property

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(_iface: String, _props: Dictionary) -> void:
		updated.emit()
	
	func get_object_path() -> String:
		return _proxy.path


## https://people.freedesktop.org/~lkundrak/nm-docs/gdbus-org.freedesktop.NetworkManager.Settings.html
class Settings extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(_iface: String, _props: Dictionary) -> void:
		updated.emit()
	
	func get_object_path() -> String:
		return _proxy.path


## https://people.freedesktop.org/~lkundrak/nm-docs/gdbus-org.freedesktop.NetworkManager.Settings.Connection.html
class Connection extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(_iface: String, _props: Dictionary) -> void:
		updated.emit()
	
	func get_object_path() -> String:
		return _proxy.path

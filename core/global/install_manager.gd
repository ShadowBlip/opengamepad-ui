extends Resource
class_name InstallManager

signal install_started(request: Request)
signal install_queued(request: Request)
signal install_completed(request: Request)
signal uninstall_completed(request: Request)

enum REQUEST_TYPE {
	INSTALL,
	UNINSTALL,
	UPDATE,
}

var _current_req: Request
var _install_queue: Array[Request] = []
var logger := Log.get_logger("InstallManager")


## Returns the currently processing install request
func get_installing() -> Request:
	return _current_req


## Installs the given library launch item using its provider
func install(request: Request) -> void:
	request._type = REQUEST_TYPE.INSTALL
	_queue_install(request)
	_process_install_queue()


## Updates the given library launch item using its provider
func update(request: Request) -> void:
	request._type = REQUEST_TYPE.UPDATE
	_queue_install(request)
	_process_install_queue()


## Uninstalls the given library launch item using its provider
func uninstall(request: Request) -> void:
	request._type = REQUEST_TYPE.UNINSTALL
	var on_completed := func(_i: LibraryLaunchItem, success: bool):
		request.completed.emit(success)
		uninstall_completed.emit(request)
	request.provider.uninstall_completed.connect(on_completed, CONNECT_ONE_SHOT)
	request.provider.uninstall(request.item)


## Returns whether or not the given launch item is queued for install
func is_queued(item: LibraryLaunchItem) -> bool:
	for req in _install_queue:
		if req.item == item:
			return true
	return false


## Returns whether or not the given launch item is currently being installed
func is_installing(item: LibraryLaunchItem) -> bool:
	return _current_req and _current_req.item == item


## Returns whether or not the given launch item is being installed or queued for install.
func is_queued_or_installing(item: LibraryLaunchItem) -> bool:
	return is_queued(item) or is_installing(item)


func _queue_install(req: Request) -> void:
	logger.info("Queuing item to be installed: " + req.item.name)
	_install_queue.push_back(req)
	install_queued.emit(req)


func _process_install_queue() -> void:
	# Don't process if the queue is empty or an active install is in progress
	if _install_queue.size() == 0 or _current_req != null:
		return
		
	# Pop the next install request in the queue
	var req := _install_queue.pop_front() as Request
	_current_req = req
	logger.info("Starting install of: " + req.item.name)
	
	# Connect to progress updates
	var on_progress := func(item: LibraryLaunchItem, progress: float):
		req.progress = progress
		req.progressed.emit(progress)
	req.provider.install_progressed.connect(on_progress)
	
	# Install the given application using the given provider
	install_started.emit(req)
	var result: Array
	match req._type:
		REQUEST_TYPE.INSTALL:
			req.provider.install_to(req.item, req.location, req.options)
			result = await req.provider.install_completed
		REQUEST_TYPE.UPDATE:
			req.provider.update(req.item)
			result = await req.provider.update_completed
		_:
			logger.warn("Unknown request type:", req._type)
			result = [req.item, false]
	req.success = result[1]
	logger.info("Install of '" + req.item.name + "' completed with success: " + str(req.success))
	
	# Disconnect from progress updates
	req.provider.install_progressed.disconnect(on_progress)
	
	# Clear the current install request
	_current_req = null
	req.completed.emit(req.success)
	install_completed.emit(req)
	
	# Process more items in the queue if they exist
	_process_install_queue.call_deferred()


## An InstallManager Request defines a queued or in-progress app install
class Request extends RefCounted:
	signal progressed(progress: float)
	signal completed(success: bool)
	var provider: Library
	var item: LibraryLaunchItem
	var location: Library.InstallLocation
	var options: Dictionary
	var progress: float
	var success: bool
	var _type: REQUEST_TYPE
	
	func _init(library_provider: Library, launch_item: LibraryLaunchItem, to_location: Library.InstallLocation = null, opts: Dictionary = {}) -> void:
		provider = library_provider
		item = launch_item
		location = to_location
		options = opts

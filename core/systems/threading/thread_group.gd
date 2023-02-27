extends Resource
class_name ThreadGroup

## Resource that allows nodes to run in a separate thread
##
## NodeThreads can belong to a ThreadGroup which will run their _thread_process
## method in the given thread

var thread: Thread
var mutex := Mutex.new()
var running := false
var nodes: Array[NodeThread] = []
var logger := Log.get_logger("ThreadGroup", Log.LEVEL.DEBUG)

## Name of the thread group
@export var name := "ThreadGroup"
## Target rate to run at in ticks per second
@export var target_tick_rate := 60


func _init() -> void:
	pass


## Starts the thread for the thread group
func start() -> void:
	if running:
		return
	running = true
	thread = Thread.new()
	thread.start(_run)
	logger.info("Thread group started: " + name)


## Stops the thread for the thread group
func stop() -> void:
	if not running:
		return
	mutex.lock()
	running = false
	mutex.unlock()
	thread.wait_to_finish()
	logger.info("Thread group stopped: " + name)


## Add the given [NodeThread] to the list of nodes to process. This should
## happen automatically by the [NodeThread]
func add_node(node: NodeThread) -> void:
	mutex.lock()
	nodes.append(node)
	mutex.unlock()
	logger.debug("Added node: " + str(node))


## Remove the given [NodeThread] from the list of nodes to process. This should
## happen automatically when the [NodeThread] exits the scene tree.
func remove_node(node: NodeThread, stop_on_empty: bool = true) -> void:
	mutex.lock()
	nodes.erase(node)
	mutex.unlock()
	logger.debug("Removed node: " + str(node))
	if stop_on_empty and nodes.size() == 0:
		stop()


func _run() -> void:
	var exited := false
	var current_tick_rate = target_tick_rate
	var target_frame_time_us := get_target_frame_time()
	var last_time := Time.get_ticks_usec()
	while not exited:
		# If the tick rate has changed, update it.
		if target_tick_rate != current_tick_rate:
			current_tick_rate = target_tick_rate
			target_frame_time_us = get_target_frame_time()

		# Start timing how long this frame takes
		var start_time := Time.get_ticks_usec()

		# Calculate the delta between frames
		var last_delta_us := start_time - last_time
		last_time = start_time
		var delta := last_delta_us / 1000000.0

		# Process everything in the thread group
		mutex.lock()
		exited = not running
		_process(delta)
		mutex.unlock()

		# Calculate how long this frame took
		var end_time := Time.get_ticks_usec()
		var delta_us := end_time - start_time  # Time in microseconds since last input frame

		# If the last frame took less time than our target frame
		# rate, sleep for the difference.
		var sleep_time_us := target_frame_time_us - delta_us
		if delta_us < target_frame_time_us:
			OS.delay_usec(sleep_time_us)  # Throttle to save CPU
		else:
			var msg := (
				"{0} missed target frame time {1}us. Got: {2}us"
				. format([name, target_frame_time_us, delta_us])
			)
			logger.debug(msg)


func _process(delta: float) -> void:
	for node in nodes:
		node._thread_process(delta)


## Returns the target frame time in microseconds of the ThreadGroup
func get_target_frame_time() -> int:
	return int((1.0 / target_tick_rate) * 1000000.0)
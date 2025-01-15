extends RefCounted
class_name FilesystemObject

var path: String


func _init(path_to: String) -> void:
	path = path_to


## Returns the mime type of the given filesystem object
func get_mime_type() -> String:
	var cmd := Command.new("xdg-mime", ["query", "filetype", path])
	var code := await cmd.execute()
	if code != OK:
		return ""
	
	return cmd.stdout


## Return the icon texture for this node
func get_icon() -> Texture2D:
	return null

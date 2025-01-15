extends Control

var HOME := OS.get_environment("HOME")

@onready var line_edit := $%LineEdit as LineEdit
@onready var tree1 := $%Tree1 as Tree

# https://unix.stackexchange.com/questions/419895/if-i-have-a-mime-type-how-do-i-get-its-associated-icon-from-the-current-appearan

# Get mime type:
#   $ xdg-mime query filetype entrypoint.gd
#   application/x-gdscript

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line_edit.text = HOME
	
	var root := tree1.create_item()
	for dir in DirAccess.get_directories_at(HOME):
		var item := root.create_child()
		item.set_text(0, dir)
	
	for file in DirAccess.get_files_at(HOME):
		var item := root.create_child()
		item.set_text(0, file)

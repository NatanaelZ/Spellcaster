@tool
extends EditorPlugin

var inspector_plugin: EditorInspectorPlugin

func _enter_tree():
	var script_path = "res://addons/dynamic_object_tools/inspector_plugin.gd"
	
	# Force le rechargement en ignorant le cache
	var script = ResourceLoader.load(script_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	
	inspector_plugin = script.new()
	add_inspector_plugin(inspector_plugin)

func _exit_tree():
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)

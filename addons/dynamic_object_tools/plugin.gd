@tool
extends EditorPlugin

var inspector_plugin: EditorInspectorPlugin

func _enter_tree():
	var script_path = "res://addons/dynamic_object_tools/inspector_plugin.gd"
	
	# Force le rechargement en ignorant le cache
	var script = ResourceLoader.load(script_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	
	inspector_plugin = script.new()
	add_inspector_plugin(inspector_plugin)

	# var editor_theme = EditorInterface.get_editor_theme()
	
	# if not editor_theme:
	# 	print("editor_theme est null aussi, on utilisera le fallback plus bas")
	# 	return
	
	# for type_name in ["EditorInspectorSection", "EditorInspectorCategory", "Inspector"]:
	# 	print("--- ", type_name, " ---")
	# 	for color_name in editor_theme.get_color_list(type_name):
	# 		print(color_name, " = ", editor_theme.get_color(color_name, type_name))
	# 	for style_name in editor_theme.get_stylebox_list(type_name):
	# 		var sb = editor_theme.get_stylebox(style_name, type_name)
	# 		if sb is StyleBoxFlat:
	# 			print(style_name, " (StyleBoxFlat) bg_color = ", sb.bg_color)

func _exit_tree():
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)

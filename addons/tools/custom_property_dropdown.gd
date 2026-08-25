@tool
class_name CustomPropertyDropdown
extends EditorProperty

var dropdown := OptionButton.new()
var items: Array[String]
var obj_ref: WeakRef
var target_node_type: StringName
# var extractor: Callable

func _init(obj:Node, dropdown_items:Array[String]):

	obj_ref = weakref(obj)
	# target_node_type = node_type
	# extractor = extract_func

	add_child(dropdown)

	auto_translate_mode = Control.AUTO_TRANSLATE_MODE_DISABLED
	dropdown.auto_translate_mode = Control.AUTO_TRANSLATE_MODE_DISABLED
	dropdown.get_popup().auto_translate_mode = Control.AUTO_TRANSLATE_MODE_DISABLED
	dropdown.expand_icon = true

	dropdown.item_selected.connect(_on_selected)
	set_process(true)

func _process(_delta: float):
	var obj = obj_ref.get_ref() as Node
	if not obj: return
	
	# var items = _call_extractor(node)
	#if items.is_empty():
		#items = ["[Aucune valeur]"]

	dropdown.clear()
	dropdown.auto_translate_mode = Control.AUTO_TRANSLATE_MODE_DISABLED
	dropdown.add_item("[Aucune]", 0)
	for item in items:
		dropdown.add_item(item)
	
	var current_val = obj.get(get_edited_property())
	for i in dropdown.item_count:
		if dropdown.get_item_text(i) == current_val:
			dropdown.select(i)
			break

# func _call_extractor(node: Node) -> Array[String]:
# 	var result = extractor.call(node)
	
# 	if result == null:
# 		return []
	
# 	if result is Array or result is PackedStringArray:
# 		var typed_array: Array[String] = []
# 		for item in result:
# 			typed_array.append(str(item))
# 		return typed_array
	
# 	push_error("DotChildPropertiesDropdown: L'extracteur doit retourner un Array, mais a retourné %s" % typeof(result))
# 	return []

# func _find_target_node(obj: Node) -> Node:
# 	for child in obj.get_children():
# 		if child.is_class(target_node_type):
# 			return child
# 	return null

func _on_selected(index: int):
	var obj = obj_ref.get_ref() as Node
	if not obj: return
	var text = dropdown.get_item_text(index)
	emit_changed(get_edited_property(), text if text != "[Aucune]" else "")

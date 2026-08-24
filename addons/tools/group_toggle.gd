@tool
class_name DotGroupToggle 
extends EditorProperty

var checkbox := CheckBox.new()
var obj_ref: WeakRef
var property_name: String
var group_name: String
var updating := false
var group_properties: Array[String] = []

func _init(obj: Node, p_property_name: String, p_group_name: String, label: String):
	obj_ref = weakref(obj)
	property_name = p_property_name
	group_name = p_group_name
	add_child(checkbox)
	checkbox.text = label
	checkbox.toggled.connect(_on_toggled)
	_set_group_properties()
	_refresh_from_object()

func _refresh_from_object():
	updating = true
	var obj = obj_ref.get_ref()
	if obj:
		checkbox.button_pressed = obj.get(property_name)
	updating = false

func _on_toggled(pressed: bool):
	if updating: return
	var obj = obj_ref.get_ref()
	if not obj: return
	obj.set(property_name, pressed)
	emit_changed(get_edited_property(), pressed)
	obj.notify_property_list_changed()

func _set_group_properties():
	var obj = obj_ref.get_ref()
	if not obj: return
	var properties: Array[String] = []
	var in_target_group = false
	
	for prop in obj.get_property_list():
		if prop.usage & PROPERTY_USAGE_GROUP:
			in_target_group = (prop.name == group_name)
			continue
		if in_target_group and prop.name != "":
			properties.append(prop.name)
	
	group_properties = properties

func get_group_properties()-> Array[String]:
	return group_properties

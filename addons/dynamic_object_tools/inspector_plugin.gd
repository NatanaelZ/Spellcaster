@tool
extends EditorInspectorPlugin

var toggles: Dictionary = {}
var machine_state: DynamicObjectStateMachine
	
func _can_handle(object: Object) -> bool:
	if object is PlayAnimationAction : 
		var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
		if (selected_nodes.size() == 1 && selected_nodes[0] is DynamicObjectStateMachine) :
			machine_state = selected_nodes[0]
			return true
	if object is DynamicObjectStateMachine:
		return true
	return false


func _parse_property(object: Object, type: Variant.Type, name: String, hint: PropertyHint, hint_string: String, usage: int, wide: bool) -> bool:
	
	# if name == "vision_behaviour_enabled":
	# 	var visionToggle = DotGroupToggle.new(object, "vision_behaviour_enabled", "Vision Behaviour", "Vision Behaviour")
	# 	add_property_editor(name, visionToggle)
	# 	toggles[name] = visionToggle
	# 	return true
	
	# for toggle_prop in toggles:
	# 	if not object.get(toggle_prop):
	# 		var toggle = toggles[toggle_prop]
	# 		if name in toggle.get_group_properties():
	# 			return true
	
	# if name == "animation_name":
	# 	var animated_sprite = machine_state.get_parent().get_node("AnimatedSprite2D")
	# 	var animations = DotExtractors.extract_animations(animated_sprite)
	# 	print(animations)
	# 	add_property_editor(name, CustomPropertyDropdown.new(animations))
	# 	return true

	if name == "initial_state_name":
		var state_names: Array[String] = []
		for state in object.states:
			state_names.append(state.name)
		add_property_editor(name, CustomPropertyDropdown.new(state_names))
		return true

	if name == "states":
		add_property_editor(name, DotCustomStatesDisplay.new())
		return true

	return false





























#class AnimationDropdown extends EditorProperty:
	#var dropdown := OptionButton.new()
	#var obj_ref: WeakRef
#
	#func _init(obj: Node):
		#obj_ref = weakref(obj)
		#add_child(dropdown)
		#dropdown.expand_icon = true
		#dropdown.item_selected.connect(_on_selected)
		#set_process(true)
#
	#func _process(_delta: float):
		#var obj = obj_ref.get_ref() as Node
		#if not obj: return
#
		#var sprite: AnimatedSprite2D = null
		#for child in obj.get_children():
			#if child is AnimatedSprite2D:
				#sprite = child
				#break
#
		#var anims = sprite.sprite_frames.get_animation_names()
		#if anims.size() == 1 && anims[0] == "default":
			#anims = []
#
		#dropdown.clear()
		#dropdown.add_item("[Aucune animation]", -1)
		#for anim in anims:
			#dropdown.add_item(anim)
		#
		#var current_val = obj.get(get_edited_property())
		#
		#for i in dropdown.item_count:
			#if dropdown.get_item_text(i) == current_val:
				#dropdown.select(i)
				#break
#
	#func _on_selected(index: int):
		#var obj = obj_ref.get_ref() as Node
		#if not obj: return
		#
		#var text = dropdown.get_item_text(index)
		#emit_changed(get_edited_property(), text)
		
		

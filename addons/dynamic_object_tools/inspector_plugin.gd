@tool
extends EditorInspectorPlugin

var toggles: Dictionary = {}
	
func _can_handle(object: Object) -> bool:
	return object is DynamicObject

func _parse_property(object: Object, type: Variant.Type, name: String, hint: PropertyHint, hint_string: String, usage: int, wide: bool) -> bool:
	
	if name == "vision_behaviour_enabled":
		var visionToggle = DotGroupToggle.new(object, "vision_behaviour_enabled", "Vision Behaviour", "Vision Behaviour")
		add_property_editor(name, visionToggle)
		toggles[name] = visionToggle
		return true
	
	for toggle_prop in toggles:
		if not object.get(toggle_prop):
			var toggle = toggles[toggle_prop]
			if name in toggle.get_group_properties():
				return true
	
	if name in ["seen_animation", "unseen_animation", "seen_animation_intro", "unseen_animation_intro"]:
		add_property_editor(name, DotChildPropertiesDropdown.new(object, "AnimatedSprite2D", DotExtractors.extract_animations))
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
		
		

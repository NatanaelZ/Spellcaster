@tool
class_name UiToolBox
extends RefCounted

static func make_bold_font(embolden: float) -> FontVariation:
	var font = FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = embolden
	return font

static func select_option_by_text(dropdown: OptionButton, text: String) -> void:
	for i in dropdown.item_count:
		if dropdown.get_item_text(i) == text:
			dropdown.select(i)
			return


static func build_custom_dropdown (dropdown_items: Array, obj: Object, property_name: String, on_change : Callable, none_label: String = ""):
	var dropdown = OptionButton.new()
	dropdown.auto_translate_mode = Control.AUTO_TRANSLATE_MODE_DISABLED
	dropdown.get_popup().auto_translate_mode = Control.AUTO_TRANSLATE_MODE_DISABLED

	if none_label != "":
		dropdown.add_item(none_label)
	elif (dropdown_items.size() == 0):
		dropdown.add_item("None")

	for item in dropdown_items:
		dropdown.add_item(item)

	var prop_info = obj.get_property_list().filter(func(p): return p.name == property_name)
	var is_enum = not prop_info.is_empty() and prop_info[0].type in [TYPE_INT, TYPE_FLOAT]
	if is_enum:
		dropdown.select(obj.get(property_name) as int)
	else:
		var val = str(obj.get(property_name))
		if val == "" and dropdown_items.size() > 0:
			val = str(dropdown_items[0])
			obj.set(property_name, val)
			on_change.call_deferred()
		UiToolBox.select_option_by_text(dropdown, val)

	dropdown.item_selected.connect(func(idx):
		if is_enum:
			obj.set(property_name, idx)
		else:
			obj.set(property_name, dropdown.get_item_text(idx))
		on_change.call())
		
	return dropdown


static func build_property_row(label_text: String, value_control: Control) -> Control:
	var wrapper = EditorPanelBox.new("v") \
		.margin_each(0, 3, 0, 3) \
		.expand_horizontal()

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 14)
	row.add_child(label)

	value_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value_control)

	row.resized.connect(func():
		if row.size.x == 0:
			return
		var half = (row.size.x - 4) / 2.0
		label.custom_minimum_size.x = half
		value_control.custom_minimum_size.x = half
	)

	wrapper.box.add_child(row)
	return wrapper.root
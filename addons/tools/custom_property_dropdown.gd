@tool
class_name CustomPropertyDropdown
extends EditorProperty

var dropdown := OptionButton.new()
var items: Array[String]

func _init(dropdown_items: Array[String]):
	add_child(dropdown)

	auto_translate_mode = Control.AUTO_TRANSLATE_MODE_DISABLED
	dropdown.auto_translate_mode = Control.AUTO_TRANSLATE_MODE_DISABLED
	dropdown.get_popup().auto_translate_mode = Control.AUTO_TRANSLATE_MODE_DISABLED
	dropdown.expand_icon = true

	items = dropdown_items
	dropdown.item_selected.connect(_on_selected)
	set_process(true)

func _process(_delta: float):
	var obj = get_edited_object()
	if not obj:
		return

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

func _on_selected(index: int):
	var text = dropdown.get_item_text(index)
	emit_changed(get_edited_property(), text if text != "[Aucune]" else "")
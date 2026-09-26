@tool
class_name DotCustomStatesDisplayV2
extends EditorProperty

var _outer_box: VBoxContainer

func _init():
	var outer_block = EditorPanelBox.new("v") \
		.bg(Color(0.27, 0.3, 0.36, 1)) \
		.corner(6) \
		.separation(0)
	add_child(outer_block.root)
	_outer_box = outer_block.box

	label = ""
	set_bottom_editor(outer_block.panel)
	add_focusable(outer_block.panel)


func _update_property():
	_clear_ui()
	_rebuild_ui()


func _clear_ui():
	for child in _outer_box.get_children():
		_outer_box.remove_child(child)
		child.queue_free()


func _rebuild_ui():
	var obj = get_edited_object()
	var states: Array = obj.get(get_edited_property())
	if states == null:
		return

	_build_title("States", 0.5)

	var all_block = EditorPanelBox.new("v") \
		.bg(Color("171b21")) \
		.padding(0) \
		.separation(0) \
		.expand_horizontal() \
		.add_to(_outer_box)

	for i in states.size():
		var state = states[i]
		if state == null:
			continue
		_build_state(all_block.box, state, i, states)

	var add_btn = Button.new()
	add_btn.text = "+ Add State"
	add_btn.pressed.connect(_on_add_state)
	_outer_box.add_child(add_btn)


func _build_title(text: String, embolden: float):
	var block = EditorPanelBox.new("v") \
		.bg(Color(0.19, 0.21, 0.25, 1)) \
		.expand_horizontal() \
		.add_to(_outer_box)
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_font_override("font", _make_bold_font(embolden))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block.add_child(label)


func _build_state(parent: VBoxContainer, state, i: int, states: Array):
	var state_block = EditorPanelBox.new("v") \
		.bg(Color(0.13, 0.15, 0.18, 1)) \
		.border_each(10, 0, 0, 0, Color("303640")) \
		.separation(0) \
		.margin_each(8, 8, 8, 0) \
		.expand_horizontal() \
		.add_to(parent)

	_build_state_header(state_block.box, state, i)
	_build_triggers(state_block.box, state, i, states)

	var actions_label = Label.new()
	actions_label.text = "Actions: " + str(state.actions.size()) + " action(s)"
	state_block.box.add_child(actions_label)


func _build_state_header(parent: VBoxContainer, state, i: int):
	var block = EditorPanelBox.new("h") \
		.bg(Color(0.19, 0.21, 0.25, 1)) \
		.padding_each(5, 0, 0, 0) \
		.expand_horizontal() \
		.add_to(parent)

	var title = Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text = state.name if state.name else "(sans nom)"
	title.add_theme_font_size_override("font_size", 14)
	block.add_child(title)

	var delete_btn = Button.new()
	delete_btn.text = "x"
	delete_btn.focus_mode = Control.FOCUS_NONE
	var btn_style = StyleBoxEmpty.new()
	btn_style.content_margin_left = 10
	btn_style.content_margin_right = 10
	for state_name in ["normal", "pressed", "disabled", "hover_pressed"]:
		delete_btn.add_theme_stylebox_override(state_name, btn_style)
	delete_btn.add_theme_font_size_override("font_size", 14)
	delete_btn.pressed.connect(_on_delete_state.bind(i))
	block.box.add_child(delete_btn)


func _build_triggers(parent: VBoxContainer, state, i: int, states: Array):
	var block = EditorPanelBox.new("v") \
		.bg(Color("272d37")) \
		.corner_each(0, 5, 5, 0) \
		.padding(5) \
		.separation(0) \
		.margin_each(10, 10, 10, 10) \
		.expand_horizontal() \
		.add_to(parent)

	_build_triggers_header(block.box)
	_build_triggers_list(block.box, state, states)


func _build_triggers_header(parent: VBoxContainer):
	var block = EditorPanelBox.new("v") \
		.bg(Color("272d37")) \
		.padding_each(0, 0, 0, 10) \
		.expand_horizontal() \
		.add_to(parent)
	var label = Label.new()
	label.text = "Triggers"
	label.add_theme_font_override("font", _make_bold_font(0.2))
	label.add_theme_font_size_override("font_size", 14)
	block.add_child(label)


func _build_triggers_list(parent: VBoxContainer, state, states: Array):
	var block = EditorPanelBox.new("v") \
		.separation(0) \
		.margin_each(5, 0, 0, 0) \
		.expand_horizontal() \
		.add_to(parent)

	for j in state.triggers.size():
		var trigger = state.triggers[j]
		var trigger_container = VBoxContainer.new()
		trigger_container.add_theme_constant_override("separation", 0)
		block.box.add_child(trigger_container)

		var separator = HSeparator.new()
		trigger_container.add_child(separator)

		var event_dropdown = OptionButton.new()
		for event_name in DynamicObjectTrigger.EventType.keys():
			event_dropdown.add_item(event_name)
		event_dropdown.select(trigger.event_type)
		event_dropdown.item_selected.connect(func(idx):
			trigger.event_type = idx
			emit_changed(get_edited_property(), states))
		trigger_container.add_child(_create_property_row("Event Type", event_dropdown, str(j) + ")"))

		var target_label = Label.new()
		target_label.text = "Target State : " + trigger.target_state
		trigger_container.add_child(_create_property_row("Target State : ", target_label, ""))

		event_dropdown.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		target_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())


func _make_bold_font(embolden: float) -> FontVariation:
	var font = FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = embolden
	return font


func _create_property_row(label_text: String, value_control: Control, prefix: String = "") -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var prefix_label = Label.new()
	prefix_label.text = prefix
	prefix_label.custom_minimum_size.x = 24
	row.add_child(prefix_label)

	var name_label = Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_stretch_ratio = 1.0
	row.add_child(name_label)

	value_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_control.size_flags_stretch_ratio = 1.0
	row.add_child(value_control)

	return row


func _on_delete_state(index: int):
	var obj = get_edited_object()
	var states: Array = obj.get(get_edited_property())
	states.remove_at(index)
	emit_changed(get_edited_property(), states)


func _on_add_state():
	var obj = get_edited_object()
	var states: Array = obj.get(get_edited_property())
	var new_state = DynamicObjectState.new()
	new_state.name = "New state"
	states.append(new_state)
	emit_changed(get_edited_property(), states)
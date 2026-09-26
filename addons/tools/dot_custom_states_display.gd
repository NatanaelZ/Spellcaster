@tool
class_name DotCustomStatesDisplay
extends EditorProperty

var _container: EditorPanelBox
var _states: Array

#region Init & Lifecycle

func _init():
	_container = EditorPanelBox.new("v") \
		.bg(Color(0.27, 0.3, 0.36, 1)) \
		.corner(6) \
		.separation(0) \
		.margin(0)
	add_child(_container.root)

	set_bottom_editor(_container.root)
	add_focusable(_container.root)

#endregion

#region Main UI Build

func _update_property():
	label = ""
	_clear_ui()
	_rebuild_ui()

func _clear_ui():
	for child in _container.box.get_children():
		_container.box.remove_child(child)
		child.queue_free()

func _rebuild_ui():
	_states = get_edited_object().get(get_edited_property())
	if _states == null:
		return

	_build_title("States", 0.5)

	var all_content_container = EditorPanelBox.new("v") \
		.bg(Color("414957")) \
		.padding_each(0,0,0,8) \
		.separation(0) \
		.expand_horizontal() \
		.add_to(_container.box)

	for i in _states.size():
		var state = _states[i]
		if state == null:
			continue
		_build_state(all_content_container.box, state, i)

	var add_btn = Button.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("282d35")
	add_btn.add_theme_stylebox_override("normal", style)
	add_btn.text = "+ Add State"
	add_btn.pressed.connect(_on_add_state)
	_container.box.add_child(add_btn)


func _build_title(text: String, embolden: float):
	var title_container = EditorPanelBox.new("v") \
		.bg(Color(0.19, 0.21, 0.25, 1)) \
		.expand_horizontal() \
		.add_to(_container.box)
		
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_font_override("font", UiToolBox.make_bold_font(embolden))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title_container.add_child(label)

#endregion

#region State Blocks

func _build_state(parent: VBoxContainer, state, i: int):
	var state_container = EditorPanelBox.new("v") \
		.bg(Color("303640")) \
		.border(1, Color("272c34")) \
		.separation(10) \
		.margin_each(8, 8, 8, 0) \
		.padding_each(15, 3, 15, 15) \
		.expand_horizontal() \
		.add_to(parent)

	_build_state_header(state_container.box, state, i)
	_build_triggers(state_container.box, state, i)
	_build_actions(state_container.box, state, i)


func _build_state_header(parent: VBoxContainer, state, i: int):
	var state_header_container = EditorPanelBox.new("h") \
		.bg(Color(0.19, 0.21, 0.25, 1)) \
		.border_each(0, 0, 0, 1, Color("282d35")) \
		.padding_each(0, 10, 0, 10) \
		.expand_horizontal() \
		.add_to(parent)

	var title = LineEdit.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", UiToolBox.make_bold_font(0.5))
	var style = StyleBoxFlat.new()
	style.bg_color = Color("282d35")
	style.set_border_width_all(1)
	style.border_color = Color("3c424b")
	style.content_margin_left = 12
	title.add_theme_stylebox_override("normal", style)
	#title.add_theme_stylebox_override("focus", style)
	title.add_theme_font_size_override("font_size", 14)

	title.text = state.name if state.name else "New State"
	title.text_changed.connect(func(idx):
			state.name = idx)
	title.text_submitted.connect(func(txt):
		emit_changed(get_edited_property(), _states))
	title.focus_exited.connect(func():
		emit_changed(get_edited_property(), _states))
	state_header_container.add_child(title)

	var up_btn = Button.new()
	up_btn.text = "▲"
	up_btn.focus_mode = Control.FOCUS_NONE
	up_btn.disabled = (i == 0)
	var arrow_style = StyleBoxEmpty.new()
	arrow_style.content_margin_left = 4
	arrow_style.content_margin_right = 4
	for s in ["normal", "pressed", "disabled", "hover_pressed"]:
		up_btn.add_theme_stylebox_override(s, arrow_style)
	up_btn.add_theme_font_size_override("font_size", 12)
	up_btn.pressed.connect(_on_move_state_up.bind(i))
	state_header_container.box.add_child(up_btn)

	var down_btn = Button.new()
	down_btn.text = "▼"
	down_btn.focus_mode = Control.FOCUS_NONE
	down_btn.disabled = (i == _states.size() - 1)
	for s in ["normal", "pressed", "disabled", "hover_pressed"]:
		down_btn.add_theme_stylebox_override(s, arrow_style)
	down_btn.add_theme_font_size_override("font_size", 12)
	down_btn.pressed.connect(_on_move_state_down.bind(i))
	state_header_container.box.add_child(down_btn)

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
	state_header_container.box.add_child(delete_btn)

#endregion

#region Triggers

func _build_triggers(parent: VBoxContainer, state, i: int):
	var triggers_container = _build_subsection_box(parent, "Trigger", _on_add_trigger.bind(state))
	_build_triggers_list(triggers_container, state)


func _build_triggers_list(parent: VBoxContainer, state):

	for j in state.triggers.size():

		var trigger = state.triggers[j]

		var trigger_container = _build_list_item_box(parent, _on_delete_trigger.bind(state, j), (j==state.triggers.size()-1), j)

		var event_dropdown = UiToolBox.build_custom_dropdown(DynamicObjectTrigger.EventType.keys(), trigger, "event_type", func():
			_clear_ui()
			_rebuild_ui()
			emit_changed(get_edited_property(), _states)) 
		var style = StyleBoxFlat.new()
		style.bg_color = Color("21262e")
		event_dropdown.add_theme_stylebox_override("normal", style)	

		var event_row = UiToolBox.build_property_row("Event Type : ", event_dropdown)
		trigger_container.add_child(event_row)

		if trigger.event_type == DynamicObjectTrigger.EventType.TIMER:
			if trigger.timer_config == null:
				trigger.timer_config = DynamicObjectTimerConfig.new()

			var timer_spin = _build_timer_duration_spinbox(trigger.timer_config)
			var timer_row = UiToolBox.build_property_row("Timer Duration : ", timer_spin)
			trigger_container.add_child(timer_row)

			var start_box = _build_start_conditions_box(trigger.timer_config)
			trigger_container.add_child(start_box)

			var blocks_box = _build_block_conditions_box(trigger.timer_config)
			trigger_container.add_child(blocks_box)

		var state_names = []
		for currState in _states:
			state_names.append(currState.name)
		var target_dropdown = UiToolBox.build_custom_dropdown(state_names, trigger, "target_state", func():emit_changed(get_edited_property(), _states))
		style = StyleBoxFlat.new()
		style.bg_color = Color("21262e")
		target_dropdown.add_theme_stylebox_override("normal", style)

		var target_row = UiToolBox.build_property_row("Target State : ", target_dropdown)
		trigger_container.add_child(target_row)

#endregion

#region Actions

func _build_actions(parent: VBoxContainer, state, i: int) :
	var actions_container = _build_subsection_box(parent, "Action", _on_add_action.bind(state))
	_build_actions_list(actions_container, state)

func _build_actions_list(parent: VBoxContainer, state) :

	for j in state.actions.size() :
		var action = state.actions[j]
		var action_container = _build_list_item_box(parent, _on_delete_action.bind(state, j), (j == state.actions.size() - 1), j)

		var picker = EditorResourcePicker.new()
		picker.base_type = "DynamicObjectAction"
		picker.edited_resource = action
		picker.resource_changed.connect(func(res):
			state.actions[j] = res
			emit_changed(get_edited_property(), _states))
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_container.add_child(picker)

		var props_box = VBoxContainer.new()
		props_box.add_theme_constant_override("separation", 0)
		props_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_container.add_child(props_box)

		var editor = ActionPropertyDisplay.build_action_property_display(action, get_edited_object().get_parent(), func():emit_changed(get_edited_property(), _states))
		
		if editor:
			props_box.add_child(editor)

#endregion

#region Shared Helpers

func _build_subsection_box(parent: VBoxContainer, subsection_name: String, add_action: Callable):
	var subsection_container = EditorPanelBox.new("v") \
		.bg(Color("272d37")) \
		.border(1, Color("3c424b")) \
		.corner_each(0, 5, 5, 0) \
		.padding(5) \
		.separation(0) \
		.expand_horizontal() \
		.add_to(parent)

	_build_state_param_header(subsection_name + "s", subsection_container.box)

	var subsection_content_container = VBoxContainer.new()
	subsection_container.box.add_child(subsection_content_container)

	var add_btn = Button.new()
	add_btn.text = "+ Add " + subsection_name
	add_btn.pressed.connect(add_action)
	subsection_container.box.add_child(add_btn)

	return subsection_content_container


func _build_list_item_box(parent: VBoxContainer, delete_action: Callable, bottom_border: bool, index: int=-1): 
	var sep = HSeparator.new()
	parent.add_child(sep)

	var item_container = EditorPanelBox.new("h") \
		.separation(0) \
		.expand_horizontal() \
		.add_to(parent)

	if index >= 0 :
		var prefix = Label.new()
		prefix.text = str(index + 1) + ")  "
		prefix.custom_minimum_size.x = 24
		item_container.box.add_child(prefix)

	var item_params_container = VBoxContainer.new()
	item_params_container.add_theme_constant_override("separation", 0)
	item_params_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_container.box.add_child(item_params_container)

	var delete_btn = Button.new()
	delete_btn.text = "x"
	delete_btn.focus_mode = Control.FOCUS_NONE
	var btn_style = StyleBoxEmpty.new()
	btn_style.content_margin_left = 10
	btn_style.content_margin_right = 10
	for state_name in ["normal", "pressed", "disabled", "hover_pressed"]:
		delete_btn.add_theme_stylebox_override(state_name, btn_style)
	delete_btn.add_theme_font_size_override("font_size", 14)
	delete_btn.pressed.connect(delete_action)
	item_container.box.add_child(delete_btn)

	if (bottom_border) :
		sep = HSeparator.new()
		parent.add_child(sep)

	return item_params_container


func _build_state_param_header(title: String, state_params_container: VBoxContainer) :
	var actions_header_container = EditorPanelBox.new("h") \
		.bg(Color("272d37")) \
		.padding_each(0, 0, 0, 0) \
		.expand_horizontal() \
		.add_to(state_params_container)
	var label = Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14)
	actions_header_container.add_child(label)


func _build_timer_duration_spinbox(timer_config: DynamicObjectTimerConfig) -> SpinBox:
	var spin = SpinBox.new()
	spin.allow_greater = true
	spin.allow_lesser = true
	spin.min_value = 0.1
	spin.max_value = 999.0
	spin.step = 0.1
	spin.value = timer_config.timer_duration
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spin_style = StyleBoxFlat.new()
	spin_style.bg_color = Color("21262e")
	spin_style.content_margin_left = 6
	spin_style.content_margin_right = 6
	spin.get_line_edit().add_theme_stylebox_override("normal", spin_style)
	spin.add_theme_stylebox_override("normal", spin_style)
	spin.value_changed.connect(func(v: float):
		timer_config.timer_duration = v
		emit_changed(get_edited_property(), _states))
	return spin


func _build_block_conditions_box(timer_config: DynamicObjectTimerConfig) -> Control:
	return _build_toggle_conditions_box("Blocks on :", timer_config, "block_conditions")


func _build_start_conditions_box(timer_config: DynamicObjectTimerConfig) -> Control:
	return _build_toggle_conditions_box("Starts on :", timer_config, "start_conditions")


func _build_toggle_conditions_box(label_text: String, timer_config: DynamicObjectTimerConfig, prop: String) -> Control:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size.x = 85
	box.add_child(label)

	var conditions: Array = timer_config.get(prop)
	if conditions == null:
		return box

	for ev_name in DynamicObjectTrigger.EventType.keys():
		var ev = DynamicObjectTrigger.EventType[ev_name]
		var btn = Button.new()
		btn.text = ev_name.capitalize()
		btn.toggle_mode = true
		btn.button_pressed = ev in conditions
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 12)
		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = Color("4a6fa5")
		pressed_style.set_corner_radius_all(3)
		pressed_style.content_margin_left = 6
		pressed_style.content_margin_right = 6
		pressed_style.content_margin_top = 0
		pressed_style.content_margin_bottom = 0
		btn.add_theme_stylebox_override("normal", pressed_style)
		var unpressed_style = StyleBoxFlat.new()
		unpressed_style.bg_color = Color("282d35")
		unpressed_style.set_corner_radius_all(3)
		unpressed_style.content_margin_left = 6
		unpressed_style.content_margin_right = 6
		unpressed_style.content_margin_top = 0
		unpressed_style.content_margin_bottom = 0
		btn.add_theme_stylebox_override("hover", unpressed_style)
		var style = StyleBoxFlat.new()
		style.bg_color = Color("1c1f26")
		style.set_corner_radius_all(3)
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		btn.add_theme_stylebox_override("hover_pressed", style)
		btn.toggled.connect(func(pressed: bool):
			var current: Array = timer_config.get(prop)
			if current == null:
				current = []
			var updated = current.duplicate()
			if pressed:
				if ev not in updated:
					updated.append(ev)
			else:
				updated.erase(ev)
			timer_config.set(prop, updated)
			emit_changed(get_edited_property(), _states))
		box.add_child(btn)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	margin.add_child(box)
	return margin

#endregion

#region Callbacks

func _on_delete_state(index: int):
	_states.remove_at(index)
	emit_changed(get_edited_property(), _states)

func _on_add_state():
	var new_state = DynamicObjectState.new()
	new_state.name = "New state"
	new_state.triggers.append(DynamicObjectTrigger.new())
	new_state.actions.append(PlayAnimationAction.new())
	_states.append(new_state)
	emit_changed(get_edited_property(), _states)

func _on_delete_trigger(state: DynamicObjectState, index: int):
	state.triggers.remove_at(index)
	emit_changed(get_edited_property(), _states)

func _on_add_trigger(state: DynamicObjectState):
	var new_trigger = DynamicObjectTrigger.new()
	if not _states.is_empty():
		new_trigger.target_state = _states[0].name
	state.triggers.append(new_trigger)
	emit_changed(get_edited_property(), _states)

func _on_delete_action(state: DynamicObjectState, index: int):
	state.actions.remove_at(index)
	emit_changed(get_edited_property(), _states)

func _on_add_action(state: DynamicObjectState):
	var new_action = DynamicObjectAction.new()
	state.actions.append(new_action)
	emit_changed(get_edited_property(), _states)

func _on_move_state_up(index: int):
	if index <= 0:
		return
	var temp = _states[index]
	_states[index] = _states[index - 1]
	_states[index - 1] = temp
	emit_changed(get_edited_property(), _states)

func _on_move_state_down(index: int):
	if index >= _states.size() - 1:
		return
	var temp = _states[index]
	_states[index] = _states[index + 1]
	_states[index + 1] = temp
	emit_changed(get_edited_property(), _states)

#endregion
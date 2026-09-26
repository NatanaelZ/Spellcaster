@tool
class_name DotCustomStatesDisplayV3
extends EditorProperty

var _container: VBoxContainer

##
## INITIALISATION
##
func _init():
	# EditorProperty nécessite un child visible pour s'afficher dans l'inspecteur.
	# On crée un VBoxContainer comme racine de toute l'UI custom.
	var _container_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.27, 0.3, 0.36, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	_container_panel.add_theme_stylebox_override("panel", style)
	add_child(_container_panel)
	
	_container = VBoxContainer.new()
	_container.add_theme_constant_override("separation", 0)
	_container_panel.add_child(_container)

	# Label gauche (celui que Godot affiche automatiquement à côté du widget)
	# Peut être laissé vide ou défini ici.
	label = ""
	set_bottom_editor(_container_panel)
	add_focusable(_container_panel)

##
## POINT D'ENTRÉE PRINCIPAL : appelé par Godot quand la valeur externe change
## (undo/redo, chargement de scène, modification programmatique...)
##
func _update_property():
	_clear_ui()
	_rebuild_ui()

##
## NETTOYAGE
##
func _clear_ui():
	for child in _container.get_children():
		_container.remove_child(child)
		child.queue_free()

##
## RECONSTRUCTION DE L'UI
##
func _rebuild_ui():
	# Récupération de l'array sous-jacent
	var obj = get_edited_object()
	var states: Array = obj.get(get_edited_property())

	if states == null:
		return
	
	# TITRE : "States"
	var states_title_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.19, 0.21, 0.25, 1)
	states_title_panel.add_theme_stylebox_override("panel", style)
	_container.add_child(states_title_panel)

	var states_title = Label.new()
	states_title.text = "States"
	states_title.add_theme_font_size_override("font_size", 14)
	var bold_font = FontVariation.new()
	bold_font.base_font = ThemeDB.fallback_font # ou une font spécifique si tu en as une
	bold_font.variation_embolden = .5 # simule le gras
	states_title.add_theme_font_override("font", bold_font)
	states_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	states_title_panel.add_child(states_title)
	# TITRE : "States"

	# CONTAINER DE TOUTE LA LISTE DES STATES
	var all_states_panel = PanelContainer.new()
	style = StyleBoxFlat.new()
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	# style.border_width_left = 4
	# style.border_width_right = 4
	# style.border_width_top = 4
	# style.border_width_bottom = 4
	# style.border_color = Color(0.19, 0.21, 0.25, 1)
	style.bg_color = Color("171b21")
	all_states_panel.add_theme_stylebox_override("panel", style)
	_container.add_child(all_states_panel)

	# var all_states_margin = MarginContainer.new()
	# all_states_margin.add_theme_constant_override("margin_left", 0)
	# _container.add_child(all_states_margin)

	var all_states_container = VBoxContainer.new()
	all_states_container.add_theme_constant_override("separation", 0)
	all_states_panel.add_child(all_states_container)
	# CONTAINER DE TOUTE LA LISTE DES STATES

	# Pour chaque DynamicObjectState dans l'array, on construit un bloc visuel
	for i in states.size():
		var state = states[i]

		if state == null:
			continue


		# CONTAINER D'UN STATE
		var state_margin = MarginContainer.new()
		state_margin.add_theme_constant_override("margin_left", 8)
		state_margin.add_theme_constant_override("margin_right", 8)
		state_margin.add_theme_constant_override("margin_top", 8)
		state_margin.add_theme_constant_override("margin_bottom", 0)
		all_states_container.add_child(state_margin)

		var state_panel = PanelContainer.new()
		style = StyleBoxFlat.new()
		style.border_width_left = 10
		# style.border_width_right = 4
		# style.border_width_top = 4
		# style.border_width_bottom = 4
		style.border_color = Color("303640")
		style.bg_color = Color(0.13, 0.15, 0.18, 1)
		state_panel.add_theme_stylebox_override("panel", style)
		state_margin.add_child(state_panel)
	
		var state_container = VBoxContainer.new()
		state_container.add_theme_constant_override("separation", 0)
		state_panel.add_child(state_container)
		# CONTAINER D'UN STATE


		# TITRE D'UN STATE
		var state_title_panel = PanelContainer.new()
		style = StyleBoxFlat.new()
		style.bg_color = Color(0.19, 0.21, 0.25, 1)
		style.content_margin_left = 5
		state_title_panel.add_theme_stylebox_override("panel", style)
		state_container.add_child(state_title_panel)

		var state_title_header_container = HBoxContainer.new()
		state_title_panel.add_child(state_title_header_container)

		# Nom du state
		var state_title = Label.new()
		state_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		state_title.text = state.name if state.name else "(sans nom)"
		state_title.add_theme_font_size_override("font_size", 14)
		state_title_header_container.add_child(state_title)

		# Bouton de suppression (placeholder fonctionnel)
		var delete_btn = Button.new()
		delete_btn.text = "x"
		delete_btn.focus_mode = Control.FOCUS_NONE # supprime le style "focus" du calcul

		var btn_style = StyleBoxEmpty.new()
		btn_style.content_margin_left = 10
		btn_style.content_margin_right = 10
		btn_style.content_margin_top = 0
		btn_style.content_margin_bottom = 0

		for state_name in ["normal", "pressed", "disabled", "hover_pressed"]:
			delete_btn.add_theme_stylebox_override(state_name, btn_style)

		delete_btn.add_theme_font_size_override("font_size", 14)
		
		delete_btn.pressed.connect(_on_delete_state.bind(i))
		state_title_header_container.add_child(delete_btn)
		# TITRE D'UN STATE


		# CONTAINER DES TRIGGERS
		var triggers_panel_margin = MarginContainer.new()
		triggers_panel_margin.add_theme_constant_override("margin_left", 10)
		triggers_panel_margin.add_theme_constant_override("margin_right", 10)
		triggers_panel_margin.add_theme_constant_override("margin_bottom", 10)
		triggers_panel_margin.add_theme_constant_override("margin_top", 10)
		state_container.add_child(triggers_panel_margin)

		var triggers_panel = PanelContainer.new()
		style = StyleBoxFlat.new()
		style.set_content_margin_all(5)
		style.border_width_bottom = 0
		style.border_width_top = 0
		style.border_width_right = 0
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_right = 5
		style.border_color = Color("303640")
		style.bg_color = Color("272d37")
		triggers_panel.add_theme_stylebox_override("panel", style)
		triggers_panel_margin.add_child(triggers_panel)

		var triggers_container = VBoxContainer.new()
		triggers_container.add_theme_constant_override("separation", 0)
		triggers_panel.add_child(triggers_container)
		# CONTAINER DES TRIGGERS


		# TRIGGER HEADER
		var triggers_header_panel = PanelContainer.new()
		style = StyleBoxFlat.new()
		style.bg_color = Color("272d37")
		style.content_margin_bottom = 10
		triggers_header_panel.add_theme_stylebox_override("panel", style)
		triggers_container.add_child(triggers_header_panel)

		var triggers_header = Label.new()
		bold_font = FontVariation.new()
		bold_font.base_font = ThemeDB.fallback_font # ou une font spécifique si tu en as une
		bold_font.variation_embolden = .2 # simule le gras
		triggers_header.add_theme_font_override("font", bold_font)
		triggers_header.text = "Triggers"
		triggers_header.add_theme_font_size_override("font_size", 14)
		triggers_header_panel.add_child(triggers_header)
		# TRIGGER HEADER


		# CONTAINER DE LA LISTE DES TRIGGERS
		var triggers_list_margin = MarginContainer.new()
		triggers_list_margin.add_theme_constant_override("margin_left", 5)
		triggers_container.add_child(triggers_list_margin)

		var triggers_list_container = VBoxContainer.new()
		triggers_list_container.add_theme_constant_override("separation", 0)
		triggers_list_margin.add_child(triggers_list_container)
		# CONTAINER DE LA LISTE DES TRIGGERS
		
		
		for j in state.triggers.size():
			var trigger_container = VBoxContainer.new()
			trigger_container.add_theme_constant_override("separation", 0)
			triggers_list_container.add_child(trigger_container)

			var separator = HSeparator.new()
			trigger_container.add_child(separator)

			var trigger = state.triggers[j]

			var event_type_dropdown = OptionButton.new()

			for event_name in DynamicObjectTrigger.EventType.keys():
				event_type_dropdown.add_item(event_name)
			
			event_type_dropdown.select(trigger.event_type)

			event_type_dropdown.item_selected.connect(func(idx):
					trigger.event_type = idx
					emit_changed(get_edited_property(), states))
			
			trigger_container.add_child(_create_property_row("Event Type", event_type_dropdown, str(j) + ")"))

			
			var target_state_label = Label.new()
			target_state_label.text = "Target State : " + trigger.target_state
			trigger_container.add_child(_create_property_row("Target State : ", target_state_label, ""))

			event_type_dropdown.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			target_state_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())

			#if (j != state.triggers.size() - 1):
			


		# Section actions
		var actions_label = Label.new()
		actions_label.text = "Actions: " + str(state.actions.size()) + " action(s)"
		state_container.add_child(actions_label)

		# Séparateur visuel
		# var separator = HSeparator.new()
		# all_states_container.add_child(separator)

	# --- BOUTON AJOUTER UN STATE ---
	var add_btn = Button.new()
	add_btn.text = "+ Add State"
	add_btn.pressed.connect(_on_add_state)
	_container.add_child(add_btn)


##
## CALLBACKS : CRUD minimal
##
func _create_property_row(label_text: String, value_control: Control, prefix: String = "") -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL # ← ajouté

	var prefix_label = Label.new()
	prefix_label.text = prefix
	prefix_label.custom_minimum_size.x = 24  # largeur fixe, même valeur pour toutes les lignes
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

# Supprime le state à l'index donné et notifie l'éditeur
func _on_delete_state(index: int):
	var obj = get_edited_object()
	var states: Array = obj.get(get_edited_property())
	states.remove_at(index)
	emit_changed(get_edited_property(), states)

# Ajoute un nouveau state vide
func _on_add_state():
	var obj = get_edited_object()
	var states: Array = obj.get(get_edited_property())
	var new_state = DynamicObjectState.new()
	new_state.name = "New state"
	states.append(new_state)
	emit_changed(get_edited_property(), states)
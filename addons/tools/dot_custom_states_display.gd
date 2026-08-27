@tool
class_name DotCustomStatesDisplay
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
	style.bg_color = Color(0.15, 0.15, 0.18)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	_container_panel.add_theme_stylebox_override("panel", style)
	add_child(_container_panel)
	
	_container = VBoxContainer.new()
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

	var states_title_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color8(64, 68, 76)
	states_title_panel.add_theme_stylebox_override("panel", style)
	_container.add_child(states_title_panel)

	# TITRE : "States" affiché tout en haut, en pleine largeur
	var states_title = Label.new()
	states_title.text = "v States"
	states_title.add_theme_font_size_override("font_size", 14)
	states_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	states_title_panel.add_child(states_title)

	# Pour chaque DynamicObjectState dans l'array, on construit un bloc visuel
	for i in states.size():
		var state = states[i]

		if state == null:
			continue

		# --- EN-TÊTE : nom du state ---
		var header_container = HBoxContainer.new()
		_container.add_child(header_container)

		var name_label = Label.new()
		# Le nom du state remplace l'indice numérique (0, 1, 2) du rendu natif
		name_label.text = state.name if state.name else "(sans nom)"
		name_label.add_theme_font_size_override("font_size", 18)
		header_container.add_child(name_label)

		# Bouton de suppression (placeholder fonctionnel)
		var delete_btn = Button.new()
		delete_btn.text = " × "
		delete_btn.pressed.connect(_on_delete_state.bind(i))
		header_container.add_child(delete_btn)

		# --- CONTENU DU STATE : triggers et actions (placeholders) ---
		var indent_margin = MarginContainer.new()
		indent_margin.add_theme_constant_override("margin_left", 20)
		_container.add_child(indent_margin)

		var content_vbox = VBoxContainer.new()
		indent_margin.add_child(content_vbox)



		# Section triggers
		var triggers_panel = PanelContainer.new()
		style = StyleBoxFlat.new()
		style.bg_color = Color8(29, 34, 41)
		triggers_panel.add_theme_stylebox_override("panel", style)
		content_vbox.add_child(triggers_panel)


		var triggers_container = VBoxContainer.new()
		triggers_panel.add_child(triggers_container)

		var triggers_header = Label.new()
		triggers_header.text = "Triggers"
		triggers_header.add_theme_font_size_override("font_size", 16)
		triggers_container.add_child(triggers_header)


		var triggers_content_vbox = VBoxContainer.new()

		var indent_margin_triggers = MarginContainer.new()
		indent_margin_triggers.add_theme_constant_override("margin_left", 20)
		triggers_container.add_child(indent_margin_triggers)

		indent_margin_triggers.add_child(triggers_content_vbox)
		
		print(state.triggers)
		for j in state.triggers.size() :
			var trigger = state.triggers[j]
			print(trigger)
			var trigger_label = Label.new()
			trigger_label.text = str(j) + ") Event Type : " + DynamicObjectTrigger.EventType.keys()[trigger.event_type] + " || Target State : " + trigger.target_state
			triggers_content_vbox.add_child(trigger_label)

		# Section actions
		var actions_label = Label.new()
		actions_label.text = "Actions: " + str(state.actions.size()) + " action(s)"
		content_vbox.add_child(actions_label)

		# Séparateur visuel
		var separator = HSeparator.new()
		_container.add_child(separator)

	# --- BOUTON AJOUTER UN STATE ---
	var add_btn = Button.new()
	add_btn.text = "+ Add State"
	add_btn.pressed.connect(_on_add_state)
	_container.add_child(add_btn)


##
## CALLBACKS : CRUD minimal
##

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
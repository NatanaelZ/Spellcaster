@tool
extends EditorPlugin

const MENU_LABEL := "Collapse Children of Selected"

var _cached_scene_tree: Tree = null

func _enter_tree() -> void:
	add_tool_menu_item(MENU_LABEL, _on_collapse_children_pressed)
	call_deferred("_setup_alt_click")

func _exit_tree() -> void:
	remove_tool_menu_item(MENU_LABEL)
	if _cached_scene_tree != null and _cached_scene_tree.gui_input.is_connected(_on_scene_tree_gui_input):
		_cached_scene_tree.gui_input.disconnect(_on_scene_tree_gui_input)


func _setup_alt_click() -> void:
	_cached_scene_tree = _find_scene_tree_control()
	if _cached_scene_tree == null:
		push_warning("Collapse Children: Alt+clic non branche, Tree du dock Scene introuvable au demarrage.")
		return
	_cached_scene_tree.gui_input.connect(_on_scene_tree_gui_input)


func _on_scene_tree_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or not mb.alt_pressed:
		return

	var item := _cached_scene_tree.get_item_at_position(mb.position)
	if item == null:
		return

	_collapse_all_children(item)
	_cached_scene_tree.queue_redraw()
	# On ne consomme pas l'evenement : le clic continue de selectionner
	# le noeud normalement en plus de plier ses enfants.

# Raccourci clavier global dans l'editeur : Ctrl+Alt+C
func _shortcut_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_C and key_event.ctrl_pressed and key_event.alt_pressed:
		_on_collapse_children_pressed()
		get_viewport().set_input_as_handled()


func _on_collapse_children_pressed() -> void:
	var selected_nodes := get_editor_interface().get_selection().get_selected_nodes()
	if selected_nodes.is_empty():
		push_warning("Collapse Children: aucun noeud selectionne dans la scene.")
		return

	var tree_control := _find_scene_tree_control()
	if tree_control == null:
		push_error("Collapse Children: impossible de trouver le Tree du dock Scene.")
		return

	var root_item := tree_control.get_root()
	if root_item == null:
		return

	for node in selected_nodes:
		var item := _find_tree_item_for_node(root_item, node)
		if item != null:
			_collapse_all_children(item)
		else:
			push_warning("Collapse Children: item introuvable pour le noeud '%s'." % node.name)

	tree_control.queue_redraw()


func _find_scene_tree_control() -> Tree:
	var base := get_editor_interface().get_base_control()
	# Recherche large : n'importe quel Tree dont un parent a une classe
	# contenant "SceneTree" (SceneTreeEditor, SceneTreeDock...)
	return _search_tree_with_ancestor_class(base, base, "SceneTree")


func _search_tree_with_ancestor_class(node: Node, base: Node, ancestor_hint: String) -> Tree:
	if node is Tree:
		var p := node.get_parent()
		while p and p != base:
			if ancestor_hint in p.get_class():
				return node as Tree
			p = p.get_parent()
	for child in node.get_children():
		var result := _search_tree_with_ancestor_class(child, base, ancestor_hint)
		if result != null:
			return result
	return null


func _find_tree_item_for_node(item: TreeItem, target_node: Node) -> TreeItem:
	if item == null:
		return null
	if item.get_text(0) == target_node.name:
		return item
	var child := item.get_first_child()
	while child:
		var result := _find_tree_item_for_node(child, target_node)
		if result != null:
			return result
		child = child.get_next()
	return null


func _collapse_all_children(item: TreeItem) -> void:
	var child := item.get_first_child()
	while child:
		child.collapsed = true
		_collapse_all_children(child)
		child = child.get_next()

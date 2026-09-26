@tool
class_name EditorPanelBox
extends RefCounted

## Helper réutilisable pour construire des blocs visuels stylés
## (MarginContainer > PanelContainer > VBox/HBoxContainer) dans les
## inspecteurs custom (EditorProperty, EditorInspectorPlugin).
##
## Usage typique :
##   var block = DotPanelBox.new("v") \
##       .bg(Color("272d37")) \
##       .corner(5) \
##       .separation(0) \
##       .margin(10) \
##       .add_to(parent)
##   block.box.add_child(my_label)
##
## `root`  -> le node à attacher au parent (MarginContainer)
## `panel` -> le PanelContainer, si tu veux retoucher le style après coup
## `box`   -> le VBoxContainer/HBoxContainer, là où ajouter le contenu

var root: MarginContainer
var panel: PanelContainer
var box: Container
var _style: StyleBoxFlat

func _init(orientation: String = "v"):
	root = MarginContainer.new()

	panel = PanelContainer.new()
	_style = StyleBoxFlat.new()
	panel.add_theme_stylebox_override("panel", _style)
	root.add_child(panel)

	_style.bg_color = Color(0,0,0,0)

	box = HBoxContainer.new() if orientation == "h" else VBoxContainer.new()
	panel.add_child(box)


## --- Style du fond ---

func bg(color: Color) -> EditorPanelBox:
	_style.bg_color = color
	return self

func corner(radius: int) -> EditorPanelBox:
	_style.set_corner_radius_all(radius)
	return self

func corner_each(top_left: int, top_right: int, bottom_right: int, bottom_left: int) -> EditorPanelBox:
	_style.corner_radius_top_left = top_left
	_style.corner_radius_top_right = top_right
	_style.corner_radius_bottom_right = bottom_right
	_style.corner_radius_bottom_left = bottom_left
	return self

func border(width: int, color: Color = Color.TRANSPARENT) -> EditorPanelBox:
	_style.set_border_width_all(width)
	_style.border_color = color
	return self

func border_each(left: int, top: int, right: int, bottom: int, color: Color = Color.TRANSPARENT) -> EditorPanelBox:
	_style.border_width_left = left
	_style.border_width_top = top
	_style.border_width_right = right
	_style.border_width_bottom = bottom
	_style.border_color = color
	return self


## --- Padding interne (content_margin, l'intérieur du stylebox) ---

func padding(value: int) -> EditorPanelBox:
	_style.set_content_margin_all(value)
	return self

func padding_each(left: int, top: int, right: int, bottom: int) -> EditorPanelBox:
	_style.content_margin_left = left
	_style.content_margin_top = top
	_style.content_margin_right = right
	_style.content_margin_bottom = bottom
	return self


## --- Margin externe (autour du panel, via le MarginContainer racine) ---

func margin(value: int) -> EditorPanelBox:
	return margin_each(value, value, value, value)

func margin_each(left: int, top: int, right: int, bottom: int) -> EditorPanelBox:
	root.add_theme_constant_override("margin_left", left)
	root.add_theme_constant_override("margin_top", top)
	root.add_theme_constant_override("margin_right", right)
	root.add_theme_constant_override("margin_bottom", bottom)
	return self


## --- Layout interne du VBox/HBoxContainer ---

func separation(value: int) -> EditorPanelBox:
	box.add_theme_constant_override("separation", value)
	return self

func expand_horizontal() -> EditorPanelBox:
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return self

func expand_vertical() -> EditorPanelBox:
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return self


## --- Attachement ---

func add_to(parent: Node) -> EditorPanelBox:
	parent.add_child(root)
	return self

## Ajoute directement un enfant au box interne, en retournant self pour chaîner.
func add_child(child: Control) -> EditorPanelBox:
	box.add_child(child)
	return self
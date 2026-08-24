class_name SeenUnseen
extends Node2D


signal seen
signal unseen

var is_seen = false
var _owner = null

func _ready():
	_owner = get_parent()
	if not _owner:
		push_warning("SeenUnseen must be a child of the object it controls.")
		
func set_seen():
	if is_seen:
		return
	is_seen = true
	emit_signal("seen")
	
func set_unseen():
	if !is_seen:
		return
	is_seen = false
	emit_signal("unseen")

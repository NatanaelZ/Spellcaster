class_name DynamicObjectAction
extends Node

# commentaire test
signal end_of_action

func play_action() :
	return  

func set_end_of_action():
	emit_signal("end_of_action")

class_name DynamicObjectAction
extends Resource

# commentaire test
signal end_of_action

func play_action(_dynamic_object: DynamicObject) :
	return  

func set_end_of_action():
	emit_signal("end_of_action")

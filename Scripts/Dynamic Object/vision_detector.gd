extends Area2D
class_name VisionDetector

var seen_unseen = null

func _ready():
	for child in get_parent().get_children():
		if child.name == "SeenUnseenBehavior":
			seen_unseen = child
			break
	
	if not seen_unseen:
		push_warning("VisionDetector n'a pas trouvé SeenUnseenBehavior dans le parent.")
		
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area):
	if area.name == "VisionCone" and seen_unseen :
		seen_unseen.set_seen()
		
func _on_area_exited(area):
	if area.name == "VisionCone" and seen_unseen :
		seen_unseen.set_unseen()

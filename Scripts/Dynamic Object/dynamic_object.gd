extends Area2D
class_name DynamicObject

func get_component(type: StringName) -> Node:
	for child in get_children():
		if child.is_class(type):
			return child
	return null

# @export var vision_behaviour_enabled: bool = true:
# 	set(value):
# 		vision_behaviour_enabled = value
# 		if Engine.is_editor_hint():
# 			notify_property_list_changed()
			
# @export_group("Vision Behaviour")
# @export var seen_animation_intro: String = ""
# @export var seen_animation: String = ""
# @export var unseen_animation_intro: String = ""
# @export var unseen_animation: String = ""
# @export var delay_animation_seen: float = 0.0
# @export var delay_animation_unseen: float = 0.0
# @export var activate_after_unseen: bool = false

# @onready var visual = $AnimatedSprite2D
# @onready var _seen_unseen := $SeenUnseenBehavior as SeenUnseen
# var timer_unseen: Timer
# var timer_seen: Timer

# var seen_can_play = !activate_after_unseen
# var unseen_can_play = true


# func _ready():
	
# 	if (seen_animation_intro || unseen_animation_intro):
# 		visual.animation_finished.connect(_on_animation_finished)
	
# 	_seen_unseen.seen.connect(_on_seen)
# 	_seen_unseen.unseen.connect(_on_unseen)
	
# 	if Engine.is_editor_hint():
# 		notify_property_list_changed()
		
# 	seen_can_play = !activate_after_unseen 
	
# 	timer_unseen = Timer.new()
# 	timer_unseen.wait_time = max(delay_animation_unseen, 0.001)
# 	timer_unseen.one_shot = true
# 	timer_unseen.timeout.connect(_on_timer_unseen_timeout)
# 	add_child(timer_unseen)

# 	timer_seen = Timer.new()
# 	timer_seen.wait_time = max(delay_animation_seen, 0.001)
# 	timer_seen.one_shot = true
# 	timer_seen.timeout.connect(_on_timer_seen_timeout)
# 	add_child(timer_seen)

	
# func _on_seen():
# 	print("seen")
# 	timer_unseen.stop()
# 	if (seen_can_play):
# 		timer_seen.start()
		
# func _on_unseen():
# 	print("unseen")
# 	seen_can_play = false
# 	timer_seen.stop()
# 	timer_unseen.start()
		

# func _on_timer_unseen_timeout() -> void:
# 	if unseen_animation_intro :
# 		visual.play(unseen_animation_intro)
# 	else :
# 		visual.play(unseen_animation) 

# 	seen_can_play = true

# func _on_timer_seen_timeout() -> void:
# 	if seen_animation_intro :
# 		print(seen_animation_intro)
# 		visual.play(seen_animation_intro)
# 	else :
# 		visual.play(seen_animation) 

# func _on_animation_finished():
# 	print("seen :" + visual.animation + " / " + seen_animation + " / " + seen_animation_intro)
# 	print("unseen :" + visual.animation + " / " + unseen_animation + " / " + unseen_animation_intro)
# 	if (seen_animation_intro && visual.animation == seen_animation_intro):
# 		visual.play(seen_animation)
# 	elif (unseen_animation_intro && visual.animation == unseen_animation_intro):
# 		visual.play(unseen_animation)

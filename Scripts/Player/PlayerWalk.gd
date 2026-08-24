#extends CharacterBody2D
#
#@onready var _animated_sprite = $AnimatedSprite2D
#
#func _process(_delta):
	#if Input.is_action_pressed("ui_down"):
		#_animated_sprite.play("run")
	#else:
		#_animated_sprite.stop()


extends CharacterBody2D

@export var speed = 600

@onready var _animated_sprite = $AnimatedSprite2D
@onready var vision_cone = $VisionCone

var last_frame := 0
var last_animation := ""

func _process(_delta):
	_animated_sprite.flip_h = false
	var new_animation := ""
	
	if Input.is_action_pressed("ui_down"):
		new_animation = "walk_forward"
		vision_cone.rotation = -PI/2
	elif Input.is_action_pressed("ui_left"):
		new_animation = "walk_left"
		vision_cone.rotation = 0
	elif Input.is_action_pressed("ui_up"):
		new_animation = "walk_backward"
		vision_cone.rotation = PI/2
	elif Input.is_action_pressed("ui_right"):
		new_animation = "walk_right"
		vision_cone.rotation = PI
		_animated_sprite.flip_h = true
	else:
		_animated_sprite.stop()
		last_frame = _animated_sprite.get_frame()
		last_animation = _animated_sprite.animation
		return
	
	if new_animation != "":
		if new_animation != last_animation:
			_animated_sprite.play(new_animation)
			_animated_sprite.set_frame(last_frame)
		else:
			_animated_sprite.play(new_animation)
		
		last_animation = new_animation
		last_frame = _animated_sprite.get_frame()
		
	

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed

func _physics_process(delta):
	get_input()
	move_and_slide()

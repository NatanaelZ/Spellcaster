class_name PlayAnimationAction
extends DynamicObjectAction

@export var animation_name : String = ""

func play_action(_dynamic_object: DynamicObject) :
    var animated_sprite = _dynamic_object.get_component("AnimatedSprite2D")

    if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
        animated_sprite.animation_finished.connect(_on_animation_finished.bind(animated_sprite))
    
    animated_sprite.play(animation_name)

func _on_animation_finished(visual: AnimatedSprite2D):
    if visual.animation != animation_name:
        return
    
    visual.animation_finished.disconnect(_on_animation_finished)
    set_end_of_action()
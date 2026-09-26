class_name PlayAnimationAction
extends DynamicObjectAction

@export var animation_name : String = ""

var _bound_callback: Callable

func play_action(_dynamic_object: DynamicObject) :
    var animated_sprite = _dynamic_object.get_component("AnimatedSprite2D")

    _bound_callback = _on_animation_finished.bind(animated_sprite)
    if not animated_sprite.animation_finished.is_connected(_bound_callback):
        animated_sprite.animation_finished.connect(_bound_callback)

    animated_sprite.play(animation_name)

func _on_animation_finished(visual: AnimatedSprite2D):
    if visual.animation != animation_name:
        return

    visual.animation_finished.disconnect(_bound_callback)
    set_end_of_action()
@tool
class_name ActionPropertyDisplay
extends RefCounted

static func build_action_property_display(action: DynamicObjectAction, obj: DynamicObject, on_change: Callable):
    if action is PlayAnimationAction:
        return _build_animation_properties(action, obj, on_change)
    return
            
static func _build_animation_properties(action : PlayAnimationAction, obj: DynamicObject, on_change: Callable) -> Control :
    var animation_dropdown = _build_animation_dropdown(action, obj, on_change)
    var animation_row = UiToolBox.build_property_row("Animation Name : ", animation_dropdown)
    return animation_row

static func _build_animation_dropdown(action: PlayAnimationAction, obj: DynamicObject, on_change: Callable) -> Control:
    var dropdown_items = DotExtractors.extract_animations(obj.get_node_or_null("AnimatedSprite2D"))
    var dropdown = UiToolBox.build_custom_dropdown(dropdown_items, action, "animation_name", on_change)
    var style = StyleBoxFlat.new()
    style.bg_color = Color("21262e")
    dropdown.add_theme_stylebox_override("normal", style)
    return dropdown
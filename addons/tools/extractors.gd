@tool
class_name DotExtractors

static func extract_animations(node: Node) -> PackedStringArray:
	var sprite = node as AnimatedSprite2D
	if not sprite or not sprite.sprite_frames:
		return []
		
	var anims = sprite.sprite_frames.get_animation_names()
	if anims.size() == 1 and anims[0] == "default":
		return []
	
	
	return anims

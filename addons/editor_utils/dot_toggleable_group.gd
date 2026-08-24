class_name DotToggleableGroupUtil

## Applique le masquage de header pour un objet donné, selon son mapping toggle -> groupe

static func validate_group_header(object: Object, property: Dictionary, toggle_groups: Dictionary) -> void:
	for toggle_prop in toggle_groups:
		if property.name == toggle_groups[toggle_prop]:
			if not object.get(toggle_prop):
				property.usage = PROPERTY_USAGE_NO_EDITOR

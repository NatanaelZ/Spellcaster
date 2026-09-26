class_name DynamicObjectTimerConfig
extends Resource

## Ne pas mettre le même EventType dans start_conditions et block_conditions :
## c'est un cas invalide dont le comportement est indéfini.
@export var timer_duration : float = 1.0
@export var start_conditions: Array[DynamicObjectTrigger.EventType] = []
@export var block_conditions: Array[DynamicObjectTrigger.EventType] = []
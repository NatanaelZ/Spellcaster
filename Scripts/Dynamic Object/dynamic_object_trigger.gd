class_name DynamicObjectTrigger
extends Resource

enum EventType { SEEN, UNSEEN, END_OF_ACTIONS, TIMER }

@export var target_state : String
@export var event_type : EventType
@export var timer_config : DynamicObjectTimerConfig
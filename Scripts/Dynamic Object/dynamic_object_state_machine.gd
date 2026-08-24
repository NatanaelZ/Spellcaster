class_name DynamicObjectStateMachine
extends Node

signal endofactions


var states: Array[DynamicObjectState]
var initial_state_name : String
var prev_state : DynamicObjectState
var curr_state : DynamicObjectState
var seen_unseen : SeenUnseen
var n_actions : int
var n_actions_ended : int

func _ready():
	seen_unseen = get_parent().get_node("SeenUnseenBehavior")
	seen_unseen.seen.connect(_on_seen)
	seen_unseen.unseen.connect(_on_unseen)
	endofactions.connect(_on_endofactions)

	for state in states:
		for action in state.actions:
			action.end_of_action.connect(_on_end_of_action)
	
	goto_state(initial_state_name)
	

func goto_state(stateName:String) :
	
	prev_state = curr_state

	var valid_state = false
	for state in states:
		if (state.name == stateName):
			curr_state = state
			valid_state = true
			break
	
	if (!valid_state):
		push_error ("State is not a valid state")
		return
	else :
		_set_curr_state()

func _set_curr_state():
	_set_actions()


func _set_actions():

	n_actions=0
	n_actions_ended=0
	var actions = curr_state.actions
	for action in actions :
		n_actions+=1
		action.play_action()


func _on_end_of_action() :
	n_actions_ended+=1
	if (n_actions == n_actions_ended):
		emit_signal("endofactions")
		

func _check_trigger(event_type: DynamicObjectTrigger.EventType):
	for trigger in curr_state.triggers:
		if (event_type == trigger.event_type):
			goto_state(trigger.target_state)
			return

func _on_seen():
	_check_trigger(DynamicObjectTrigger.EventType.SEEN)
	
func _on_unseen():
	_check_trigger(DynamicObjectTrigger.EventType.UNSEEN)

func _on_endofactions():
	_check_trigger(DynamicObjectTrigger.EventType.END_OF_ACTIONS)
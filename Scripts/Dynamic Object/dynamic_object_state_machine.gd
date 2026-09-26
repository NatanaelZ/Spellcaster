class_name DynamicObjectStateMachine
extends Node

signal endofactions


@export var initial_state_name : String = ""
@export var states: Array[DynamicObjectState]
var prev_state : DynamicObjectState
var curr_state : DynamicObjectState
var seen_unseen : SeenUnseen
var n_actions : int
var n_actions_ended : int
var _active_timers: Dictionary
var _started_timers: Dictionary

func _ready():
	if (states.size() == 0):
		return

	seen_unseen = get_parent().get_component("SeenUnseen")
	seen_unseen.seen.connect(_on_seen)
	seen_unseen.unseen.connect(_on_unseen)
	endofactions.connect(_on_endofactions)

	for state in states:
		for action in state.actions:
			action.end_of_action.connect(_on_end_of_action)
	
	goto_state(initial_state_name)
	

func goto_state(stateName:String) :
	
	if (curr_state) :
		prev_state = curr_state

	var valid_state = false
	for state in states:
		#print(state.name)
		if (state.name == stateName):
			curr_state = state
			valid_state = true
			break
	
	_clear_state()

	if (!valid_state):
		push_error ("State is not a valid state")
		return
	else :
		_set_curr_state()

func _set_curr_state():
	print("===" + curr_state.name + "===")
	_set_actions()
	_set_timers()

func _clear_state():
	for trigger in _active_timers:
		var timer = _active_timers[trigger]
		timer.stop()
		timer.queue_free()
	_active_timers.clear()
	_started_timers.clear()

func _set_timers():
	for trigger in curr_state.triggers:
		if trigger.timer_config != null:
			var timer = Timer.new()
			timer.wait_time = trigger.timer_config.timer_duration
			timer.one_shot = true
			timer.timeout.connect(_on_timer_timeout)
			add_child(timer)
			if trigger.timer_config.start_conditions.is_empty():
				timer.start()
			_active_timers[trigger] = timer
			_started_timers[trigger] = trigger.timer_config.start_conditions.is_empty()

func _set_actions():
	print("in")
	n_actions=0
	n_actions_ended=0
	var actions = curr_state.actions
	for action in actions :
		n_actions+=1
		action.play_action(get_parent())


func _on_end_of_action() :
	n_actions_ended+=1
	if (n_actions == n_actions_ended):
		emit_signal("endofactions")
		

func _check_trigger(event_type: DynamicObjectTrigger.EventType):
	
	for trigger in curr_state.triggers:

		if trigger.event_type == DynamicObjectTrigger.EventType.TIMER:
			var is_started: bool = _started_timers.get(trigger, false)
			if not is_started and trigger.timer_config.start_conditions.has(event_type):
				_active_timers[trigger].start()
				_started_timers[trigger] = true
			elif is_started and trigger.timer_config.block_conditions.has(event_type):
				_active_timers[trigger].stop()
				_started_timers[trigger] = false

		if (event_type == trigger.event_type):
			goto_state(trigger.target_state)
			return


func _on_seen():
	print("seen")
	_check_trigger(DynamicObjectTrigger.EventType.SEEN)
	
func _on_unseen():
	print("unseen")
	_check_trigger(DynamicObjectTrigger.EventType.UNSEEN)

func _on_endofactions():
	print("end")
	_check_trigger(DynamicObjectTrigger.EventType.END_OF_ACTIONS)

func _on_timer_timeout():
	print("timer")
	_check_trigger(DynamicObjectTrigger.EventType.TIMER)
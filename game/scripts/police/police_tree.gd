extends BeehaveTree
## Loop 3g-1: a police unit's behaviour tree (beehave), ticked by hand at 5 Hz by police.gd
## (process_thread MANUAL), never per frame. A lean `_ready`: beehave's own registers every
## tree with its editor debugger and two global autoloads (and hooks every node added to the
## scene); the game keeps the editor plugin off, so there are no such autoloads, and the
## bench's own per-system timer (police.gd `spent_usec`) stands in for beehave's custom monitor.


func _ready() -> void:
	if actor == null:
		_resolve_actor()
	# Reading it makes the internal blackboard (beehave's getter) before the first tick.
	assert(blackboard != null)
	set_physics_process(false)
	set_process(false)
